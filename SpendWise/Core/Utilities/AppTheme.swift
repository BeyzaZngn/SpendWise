import SwiftUI

/// SpendWise App Theme - Based on app icon colors
/// Consistent color palette for both light and dark modes
enum AppTheme {
    
    // MARK: - Background Gradient Colors (Slate Blue)
    static let backgroundGradientStart = Color(red: 0.42, green: 0.48, blue: 0.55)  // Light slate
    static let backgroundGradientEnd = Color(red: 0.23, green: 0.29, blue: 0.36)    // Dark slate
    
    // MARK: - Accent Colors
    static let primaryAccent = Color(red: 0.18, green: 0.80, blue: 0.44)  // Emerald Green
    static let secondaryAccent = Color(red: 0.83, green: 0.69, blue: 0.22) // Gold
    
    // MARK: - Status Colors
    static let income = Color(red: 0.18, green: 0.80, blue: 0.44)  // Emerald Green
    static let expense = Color(red: 0.91, green: 0.30, blue: 0.24) // Red
    static let warning = Color(red: 0.95, green: 0.61, blue: 0.07) // Orange/Amber
    
    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    
    // MARK: - Card/Material
    static let cardBackground = Color.white.opacity(0.1)
    
    // MARK: - Background Gradient
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundGradientStart, backgroundGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Tab Bar Tint
    static let tabBarTint = primaryAccent
}

// MARK: - View Extension for Theme Background
extension View {
    func appBackground() -> some View {
        self.background(
            AppTheme.backgroundGradient
                .ignoresSafeArea()
        )
    }
}
