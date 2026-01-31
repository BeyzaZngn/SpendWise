import Foundation

/// Currency formatting utility with locale support
struct CurrencyFormatter {
    
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
    
    /// Format a decimal value as currency
    /// - Parameter value: The decimal value to format
    /// - Returns: Formatted currency string (e.g., "$1,234.56")
    static func format(_ value: Decimal) -> String {
        formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
    }
    
    /// Format a decimal value as currency with sign
    /// - Parameters:
    ///   - value: The decimal value to format
    ///   - showPositiveSign: Whether to show + for positive values
    /// - Returns: Formatted currency string with sign
    static func formatWithSign(_ value: Decimal, showPositiveSign: Bool = true) -> String {
        let formatted = format(abs(value))
        if value < 0 {
            return "-\(formatted)"
        } else if value > 0 && showPositiveSign {
            return "+\(formatted)"
        }
        return formatted
    }
    
    /// Format as compact currency (e.g., $1.2K)
    /// - Parameter value: The decimal value to format
    /// - Returns: Compact formatted currency string
    static func formatCompact(_ value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        
        switch abs(doubleValue) {
        case 1_000_000...:
            return String(format: "$%.1fM", doubleValue / 1_000_000)
        case 1_000...:
            return String(format: "$%.1fK", doubleValue / 1_000)
        default:
            return format(value)
        }
    }
}

// MARK: - Decimal Extensions

extension Decimal {
    
    /// Format as currency string
    var currencyFormatted: String {
        CurrencyFormatter.format(self)
    }
    
    /// Format as currency string with sign
    var currencyFormattedWithSign: String {
        CurrencyFormatter.formatWithSign(self)
    }
    
    /// Format as compact currency string
    var currencyFormattedCompact: String {
        CurrencyFormatter.formatCompact(self)
    }
}
