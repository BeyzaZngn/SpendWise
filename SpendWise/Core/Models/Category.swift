import Foundation
import SwiftUI

/// Spending categories for transactions
enum Category: String, CaseIterable, Codable, Identifiable {
    case food = "Food"
    case transport = "Transport"
    case entertainment = "Entertainment"
    case bills = "Bills"
    case shopping = "Shopping"
    case health = "Health"
    case education = "Education"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .bills: return "doc.text.fill"
        case .shopping: return "bag.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .entertainment: return .purple
        case .bills: return .red
        case .shopping: return .pink
        case .health: return .green
        case .education: return .cyan
        case .other: return .gray
        }
    }
}
