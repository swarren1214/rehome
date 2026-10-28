import Charts
import SwiftData
import SwiftUI

/// The Sales tab: what she's earned this month, week by week, how fast things sell, and what
/// sold most recently.
struct SalesView: View {
    @Environment(AppRouter.self) private var router
    @Query(filter: #Predicate<Item> { $0.statusRaw == "sold" }, sort: \Item.soldAt, order: .reverse)
    private var sold: [Item]
    @State private var month = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now

    var body: some View {
        RehomeScreen("Sales", subtitle: subtitle, refresh: { await CloudRefresh.wait() }) {
            if sold.isEmpty {
                Card(padding: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "tag")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(Brand.ink)
                            .accessibilityHidden(true)
                        Text("No sales yet")
                            .font(.title3.bold())
                        Text("When something sells, mark it sold on its page and your earnings show up here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                earnings
                stats
                recent
            }
        }
        .rehomeToolbar {
            Menu {
                ForEach(months, id: \.self) { start in
                    Button {
                        month = start
                    } label: {
                        if start == month {
                            Label { Text(monthTitle(start)) } icon: { Image.menuIcon("checkmark") }
                        } else {
                            Text(monthTitle(start))
                        }
                    }
                }
            } label: {
                Label(monthTitle(month), systemImage: "calendar")
            }
        }
    }

    // MARK: - Sections

    private var earnings: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Earned in \(month.formatted(.dateTime.month(.wide)))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(Money.format(total(in: monthSales)))
                            .font(.largeTitle.bold())
                            .monospacedDigit()
                    }
                    Spacer()
                    if let change = changeFromLastMonth {
                        Text(change)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(ItemStatus.sold.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(ItemStatus.sold.fill, in: .capsule)
                    }
                }
                Chart(weeks) { week in
                    BarMark(
                        x: .value("Week", week.start, unit: .weekOfYear),
                        y: .value("Earned", Double(week.cents) / 100)
                    )
                    .foregroundStyle(Brand.berry.gradient)
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let dollars = value.as(Double.self) {
                                Text(Money.format(Int(dollars * 100)))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 160)
                .accessibilityLabel("Earnings by week")
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            statCard(averageSale.map(Money.format) ?? "–", "Average sale")
            statCard(averageDays.map { "\($0) \($0 == 1 ? "day" : "days")" } ?? "–", "Average time to sell")
            statCard(recovered.map { "\($0)%" } ?? "–", "Of retail recovered")
        }
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardLabel("Recently sold")
            VStack(spacing: 0) {
                let rows = Array(sold.prefix(12))
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, item in
                    NavigationLink(value: item) {
                        HStack(spacing: 12) {
                            PhotoTile(data: item.coverData, symbol: item.category.symbol, maxPixel: 160)
                                .frame(width: 44, height: 44)
                                .clipShape(.rect(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.displayTitle)
                                    .lineLimit(1)
                                Text(soldLine(item))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            Text(Money.format(item.soldPriceCents))
                                .font(.body.weight(.semibold))
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    if index < rows.count - 1 { Divider().padding(.leading, 68) }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
        }
    }

    // MARK: - Numbers

    private var subtitle: String {
        let count = monthSales.count
        return "\(count) \(count == 1 ? "item" : "items") sold in \(month.formatted(.dateTime.month(.wide)))"
    }

    private var monthInterval: DateInterval {
        Calendar.current.dateInterval(of: .month, for: month) ?? DateInterval(start: month, duration: 0)
    }

    private var monthSales: [Item] {
        sold.filter { item in item.soldAt.map { monthInterval.contains($0) } ?? false }
    }

    private func total(in items: [Item]) -> Int {
        items.reduce(0) { $0 + $1.soldPriceCents }
    }

    /// "+$96 vs Sept", against the month before.
    private var changeFromLastMonth: String? {
        let calendar = Calendar.current
        guard let previous = calendar.date(byAdding: .month, value: -1, to: monthInterval.start),
              let interval = calendar.dateInterval(of: .month, for: previous) else { return nil }
        let before = total(in: sold.filter { $0.soldAt.map { interval.contains($0) } ?? false })
        guard before > 0 else { return nil }
        let delta = total(in: monthSales) - before
        let sign = delta >= 0 ? "+" : "−"
        return "\(sign)\(Money.format(abs(delta))) vs \(previous.formatted(.dateTime.month(.abbreviated)))"
    }

    /// Each week that touches the month, with what sold in it.
    private var weeks: [WeekTotal] {
        let calendar = Calendar.current
        var result: [WeekTotal] = []
        var cursor = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)?.start ?? monthInterval.start
        while cursor < monthInterval.end {
            let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) ?? monthInterval.end
            let cents = monthSales
                .filter { item in item.soldAt.map { $0 >= cursor && $0 < next } ?? false }
                .reduce(0) { $0 + $1.soldPriceCents }
            result.append(WeekTotal(start: cursor, cents: cents))
            cursor = next
        }
        return result
    }

    private var averageSale: Int? {
        let items = monthSales.isEmpty ? sold : monthSales
        guard !items.isEmpty else { return nil }
        return total(in: items) / items.count
    }

    private var averageDays: Int? {
        let days = sold.compactMap(\.daysToSell)
        guard !days.isEmpty else { return nil }
        return Int((Double(days.reduce(0, +)) / Double(days.count)).rounded())
    }

    /// How much of the original price came back, across sold items with a known retail price.
    private var recovered: Int? {
        let known = sold.filter { $0.originalPriceCents > 0 }
        let retail = known.reduce(0) { $0 + $1.originalPriceCents }
        guard retail > 0 else { return nil }
        return Int((Double(total(in: known)) / Double(retail) * 100).rounded())
    }

    /// The months with sales, newest first, plus this month.
    private var months: [Date] {
        let calendar = Calendar.current
        var starts = Set<Date>()
        if let now = calendar.dateInterval(of: .month, for: .now)?.start { starts.insert(now) }
        for item in sold {
            if let soldAt = item.soldAt, let start = calendar.dateInterval(of: .month, for: soldAt)?.start {
                starts.insert(start)
            }
        }
        return starts.sorted(by: >)
    }

    private func monthTitle(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    private func soldLine(_ item: Item) -> String {
        var parts: [String] = []
        if !item.size.isEmpty { parts.append(item.sizeSystem.phrase(for: item.size)) }
        if let soldAt = item.soldAt { parts.append(soldAt.formatted(.dateTime.month(.abbreviated).day())) }
        if let days = item.daysToSell { parts.append("sold in \(days) \(days == 1 ? "day" : "days")") }
        return parts.joined(separator: " · ")
    }
}

struct WeekTotal: Identifiable {
    var start: Date
    var cents: Int
    var id: Date { start }
}
