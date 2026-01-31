import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddTransaction = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Card
                    BalanceCardView(
                        balance: viewModel.balance,
                        income: viewModel.totalIncome,
                        expense: viewModel.totalExpenses
                    )
                    .padding(.horizontal)
                    
                    // Budget Progress
                    if viewModel.overallBudgetProgress > 0 {
                        BudgetProgressCardView(
                            progress: viewModel.overallBudgetProgress,
                            spent: viewModel.totalBudgetSpent,
                            limit: viewModel.totalBudgetLimit
                        )
                        .padding(.horizontal)
                    }
                    
                    // Period Selector
                    PeriodSelectorView(selectedPeriod: $viewModel.selectedPeriod)
                        .padding(.horizontal)
                    
                    // Spending by Category
                    if !viewModel.categoryExpenses.isEmpty {
                        CategoryBreakdownView(expenses: viewModel.categoryExpenses)
                            .padding(.horizontal)
                    }
                    
                    // Recent Transactions
                    RecentTransactionsView(transactions: viewModel.recentTransactions)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .appBackground()
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Balance Card

struct BalanceCardView: View {
    let balance: Decimal
    let income: Decimal
    let expense: Decimal
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Current Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(balance.currencyFormatted)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(balance >= 0 ? Color.primary : Color.red)
            }
            
            HStack(spacing: 24) {
                IncomeExpenseView(
                    title: "Income",
                    amount: income,
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                Divider()
                    .frame(height: 40)
                
                IncomeExpenseView(
                    title: "Expense",
                    amount: expense,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct IncomeExpenseView: View {
    let title: String
    let amount: Decimal
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(amount.currencyFormatted)
                    .font(.subheadline.bold())
            }
        }
    }
}

// MARK: - Budget Progress Card

struct BudgetProgressCardView: View {
    let progress: Double
    let spent: Decimal
    let limit: Decimal
    
    private var progressColor: Color {
        if progress >= 1.0 { return .red }
        if progress >= 0.8 { return .orange }
        return .green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Monthly Budget")
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(progressColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressColor.gradient)
                        .frame(width: min(geometry.size.width * progress, geometry.size.width))
                }
            }
            .frame(height: 12)
            
            HStack {
                Text(spent.currencyFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(limit.currencyFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Period Selector

enum TimePeriod: String, CaseIterable {
    case day = "Today"
    case week = "Week"
    case month = "Month"
}

struct PeriodSelectorView: View {
    @Binding var selectedPeriod: TimePeriod
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedPeriod == period
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear
                        )
                        .foregroundStyle(
                            selectedPeriod == period
                            ? Color.accentColor
                            : .secondary
                        )
                }
            }
        }
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Category Breakdown

struct CategoryBreakdownView: View {
    let expenses: [(category: Category, total: Decimal)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
            
            ForEach(expenses.prefix(5), id: \.category) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundStyle(item.category.color)
                        .frame(width: 24)
                    
                    Text(item.category.rawValue)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(item.total.currencyFormatted)
                        .font(.subheadline.bold())
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Recent Transactions

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    TransactionListView()
                }
                .font(.subheadline)
            }
            
            if transactions.isEmpty {
                Text("No transactions yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(transactions.prefix(5)) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundStyle(transaction.category.color)
                .frame(width: 36, height: 36)
                .background(transaction.category.color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category.rawValue)
                    .font(.subheadline.weight(.medium))
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.type == .income ? "+\(transaction.amount.currencyFormatted)" : "-\(transaction.amount.currencyFormatted)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(transaction.type == .income ? .green : .primary)
                Text(transaction.date.relativeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, CoreDataManager.preview.viewContext)
}
