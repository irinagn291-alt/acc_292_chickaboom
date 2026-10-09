import Foundation

/// CSV of Items and SeatMarks. Built on device, never uploaded.
enum LedgerExport {
    static func csv(_ chart: BondChart) -> String {
        let slots = Dictionary(uniqueKeysWithValues: chart.slots.map { ($0.id, $0.name) })
        var rows = ["record,name,code,status,slot,assignee,day"]
        for item in chart.items {
            rows.append(
                [
                    "item",
                    item.name,
                    item.code ?? "",
                    item.status.title,
                    slots[item.assignedSlot] ?? "",
                    item.assignee ?? "",
                    ""
                ].map(escape).joined(separator: ",")
            )
        }
        for mark in chart.seatMarks {
            let item = chart.items.first { $0.id == mark.itemID }
            rows.append(
                [
                    "seat",
                    item?.name ?? "",
                    item?.code ?? "",
                    ItemStatus.issued.title,
                    slots[mark.slotID] ?? "",
                    mark.assignee ?? "",
                    Figures.whole(DayKey.make(mark.at))
                ].map(escape).joined(separator: ",")
            )
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

extension ItemStatus {
    /// Words on the chip. Overdue is not a stored status.
    var title: String {
        switch self {
        case .inStock: return "In stock"
        case .issued: return "Issued"
        case .relinquished: return "Relinquished"
        }
    }
}
