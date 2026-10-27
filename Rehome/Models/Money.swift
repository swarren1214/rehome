import Foundation

/// Prices are kept as whole cents (Int) so sums never drift. These turn them into what people see.
nonisolated enum Money {
    static var currencyCode: String { Locale.current.currency?.identifier ?? "USD" }

    /// "$34" for whole amounts, "$34.50" otherwise.
    static func format(_ cents: Int) -> String {
        let value = Decimal(cents) / 100
        let whole = cents % 100 == 0
        return value.formatted(
            .currency(code: currencyCode)
                .precision(.fractionLength(whole ? 0 : 2))
        )
    }

    static func decimal(_ cents: Int) -> Decimal { Decimal(cents) / 100 }

    static func cents(_ value: Decimal) -> Int {
        var scaled = value * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }
}
