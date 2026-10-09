import AVFoundation
import UIKit

/// Holds the capture session so start and stop can leave the main actor.
final class CaptureBox: @unchecked Sendable {
    let session = AVCaptureSession()

    func start() {
        if !session.isRunning { session.startRunning() }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
    }
}

/// Full-screen cover. Camera when a device exists, chips and a typed code otherwise.
@MainActor
final class ScanCoverViewController: UIViewController {
    private let store = ManifestDesk.shared.store
    private let box = CaptureBox()
    private let relay = CaptureRelay()
    private var preview: AVCaptureVideoPreviewLayer?
    private var started = false
    private var lastAt = Date.distantPast
    private var busyPayload: String?
    private let manual = UITextField()
    private let status = UILabel()
    private let deniedButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignTokens.bgUI
        overrideUserInterfaceStyle = .light
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = DesignTokens.inkUI
        close.accessibilityLabel = "Close"
        close.addTarget(self, action: #selector(closeCover), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)

        status.font = Face.body()
        status.textColor = DesignTokens.inkUI
        status.numberOfLines = 0
        status.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(status)

        manual.placeholder = "Type a code"
        manual.font = Face.body()
        manual.textColor = DesignTokens.inkUI
        manual.backgroundColor = DesignTokens.surfaceUI
        manual.layer.cornerRadius = Curve.chip
        manual.autocorrectionType = .no
        manual.autocapitalizationType = .none
        manual.translatesAutoresizingMaskIntoConstraints = false
        manual.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        manual.leftView = UIView(frame: CGRect(x: 0, y: 0, width: Gap.steps(2), height: 44))
        manual.leftViewMode = .always
        manual.accessibilityLabel = "Manual code"
        view.addSubview(manual)

        let use = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Use code"
        config.baseBackgroundColor = DesignTokens.accentUI
        config.baseForegroundColor = DesignTokens.bgUI
        config.background.cornerRadius = Curve.chip
        config.background.strokeColor = DesignTokens.inkUI
        config.background.strokeWidth = 1
        use.configuration = config
        use.addTarget(self, action: #selector(submitManual), for: .touchUpInside)
        use.translatesAutoresizingMaskIntoConstraints = false
        use.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        view.addSubview(use)

        var settingsConfig = UIButton.Configuration.plain()
        settingsConfig.title = "Open Settings"
        settingsConfig.baseForegroundColor = DesignTokens.inkUI
        deniedButton.configuration = settingsConfig
        deniedButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        deniedButton.translatesAutoresizingMaskIntoConstraints = false
        deniedButton.isHidden = true
        deniedButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        view.addSubview(deniedButton)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            close.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Gap.steps(2)),
            close.topAnchor.constraint(equalTo: guide.topAnchor, constant: Gap.steps(1)),
            close.widthAnchor.constraint(equalToConstant: 44),
            close.heightAnchor.constraint(equalToConstant: 44),
            status.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Gap.steps(2)),
            status.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Gap.steps(2)),
            status.topAnchor.constraint(equalTo: close.bottomAnchor, constant: Gap.steps(2)),
            deniedButton.leadingAnchor.constraint(equalTo: status.leadingAnchor),
            deniedButton.topAnchor.constraint(equalTo: status.bottomAnchor, constant: Gap.steps(1)),
            manual.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Gap.steps(2)),
            manual.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Gap.steps(2)),
            manual.bottomAnchor.constraint(equalTo: use.topAnchor, constant: -Gap.steps(1)),
            use.leadingAnchor.constraint(equalTo: manual.leadingAnchor),
            use.trailingAnchor.constraint(equalTo: manual.trailingAnchor),
            use.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Gap.steps(2))
        ])

        relay.onCode = { [weak self] value in
            self?.accept(value)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(leaveForeground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(returnForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        let dismissKeys = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeys.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissKeys)

        if AVCaptureDevice.default(for: .video) == nil {
            status.text = "No camera on this device. Use a sample code or type one."
            layoutChips()
        } else {
            status.text = "Point at a crate barcode or a slot plate."
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startIfAllowed()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    @objc private func leaveForeground() {
        stopSession()
    }

    @objc private func returnForeground() {
        guard view.window != nil else { return }
        startIfAllowed()
    }

    private func startIfAllowed() {
        guard AVCaptureDevice.default(for: .video) != nil else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.startSession()
                    } else {
                        self?.showDenied()
                    }
                }
            }
        case .denied, .restricted:
            showDenied()
        @unknown default:
            showDenied()
        }
    }

    private func showDenied() {
        status.text = "The camera is off. Open Settings to change it, or type the code below."
        deniedButton.isHidden = false
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func startSession() {
        guard !started else {
            let box = box
            DispatchQueue.global(qos: .userInitiated).async {
                box.start()
            }
            return
        }
        let session = box.session
        session.beginConfiguration()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            status.text = "The camera did not start. Type the code instead."
            return
        }
        session.addInput(input)
        try? device.lockForConfiguration()
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        device.unlockForConfiguration()
        let output = AVCaptureMetadataOutput()
        let frames = AVCaptureVideoDataOutput()
        frames.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(output), session.canAddOutput(frames) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        session.addOutput(frames)
        output.setMetadataObjectsDelegate(relay, queue: DispatchQueue(label: "bmk.capture"))
        output.metadataObjectTypes = [.qr, .ean13, .ean8, .upce, .code128]
        session.commitConfiguration()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        preview = layer
        started = true
        let box = box
        DispatchQueue.global(qos: .userInitiated).async {
            box.start()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }

    private func stopSession() {
        let box = box
        DispatchQueue.global(qos: .userInitiated).async {
            box.stop()
        }
    }

    private func layoutChips() {
        let codes = ["5901234123457", "4006381333931", "PLATE-BAY-A", "PLATE-DOCK", "012345678905"]
        let row = UIStackView()
        row.axis = .vertical
        row.spacing = Gap.steps(1)
        row.translatesAutoresizingMaskIntoConstraints = false
        for code in codes {
            var config = UIButton.Configuration.filled()
            config.title = code
            config.baseBackgroundColor = DesignTokens.surfaceUI
            config.baseForegroundColor = DesignTokens.inkUI
            config.background.cornerRadius = Curve.chip
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var next = incoming
                next.font = Face.caption()
                return next
            }
            let button = UIButton(configuration: config)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            button.addAction(UIAction { [weak self] _ in
                self?.accept(code)
            }, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        view.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Gap.steps(2)),
            row.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Gap.steps(2)),
            row.topAnchor.constraint(equalTo: status.bottomAnchor, constant: Gap.steps(2))
        ])
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func submitManual() {
        accept(manual.text ?? "")
    }

    @objc private func closeCover() {
        dismiss(animated: true)
    }

    private func accept(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date()
        if now.timeIntervalSince(lastAt) < 1.7 { return }
        if busyPayload == trimmed { return }
        busyPayload = trimmed
        lastAt = now
        let outcome = store.receive(payload: trimmed)
        busyPayload = nil
        if let manifest = presentingViewController?.children.compactMap({ $0 as? ManifestViewController }).first
            ?? (presentingViewController as? UINavigationController)?.viewControllers.compactMap({ $0 as? ManifestViewController }).first {
            manifest.applyOutcome(outcome)
        } else {
            store.show(query: "")
            ManifestDesk.shared.noteChanged()
        }
        switch outcome {
        case .invalid, .refused, .skewed, .drifted:
            break
        default:
            dismiss(animated: true)
        }
    }
}

/// Forwards barcodes off the session queue. Every third frame is enough.
final class CaptureRelay: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    var onCode: (@MainActor (String) -> Void)?
    private var frame = 0

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        frame += 1
        if frame % 3 != 0 { return }
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        let payload = value
        Task { @MainActor in
            self.onCode?(payload)
        }
    }
}
