import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case transactions = "Transactions"
        case reports = "Reports"
        case budget = "Budget"
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .transactions: return "arrow.left.arrow.right"
            case .reports: return "chart.pie.fill"
            case .budget: return "target"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)
            
            TransactionListView()
                .tabItem {
                    Label(Tab.transactions.rawValue, systemImage: Tab.transactions.icon)
                }
                .tag(Tab.transactions)
            
            ReportsView()
                .tabItem {
                    Label(Tab.reports.rawValue, systemImage: Tab.reports.icon)
                }
                .tag(Tab.reports)
            
            BudgetView()
                .tabItem {
                    Label(Tab.budget.rawValue, systemImage: Tab.budget.icon)
                }
                .tag(Tab.budget)
        }
        .tint(AppTheme.primaryAccent)
        .preferredColorScheme(.dark) // Force dark mode for consistent appearance
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataManager.preview.viewContext)
}
