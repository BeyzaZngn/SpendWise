import Foundation

extension DateFormatter {
    
    /// Full date formatter (e.g., "January 30, 2026")
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Short date formatter (e.g., "Jan 30")
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    /// Month and year formatter (e.g., "January 2026")
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    /// Day of week formatter (e.g., "Monday")
    static let dayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    /// Time formatter (e.g., "3:30 PM")
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Date Extensions

extension Date {
    
    /// Formatted as full date string
    var fullDateString: String {
        DateFormatter.fullDate.string(from: self)
    }
    
    /// Formatted as short date string
    var shortDateString: String {
        DateFormatter.shortDate.string(from: self)
    }
    
    /// Formatted as month and year
    var monthYearString: String {
        DateFormatter.monthYear.string(from: self)
    }
    
    /// Formatted as day of week
    var dayOfWeekString: String {
        DateFormatter.dayOfWeek.string(from: self)
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Get relative description (Today, Yesterday, or date)
    var relativeDescription: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        return shortDateString
    }
    
    /// Start of current month
    static var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    /// Start of current week
    static var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components) ?? Date()
    }
}
