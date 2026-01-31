import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @State private var selectedChart: ChartType = .pie
    @State private var selectedPeriod: ReportPeriod = .month
    
    enum ChartType: String, CaseIterable {
        case pie = "Categories"
        case trend = "Trend"
        case comparison = "Compare"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    ReportPeriodSelector(selectedPeriod: $selectedPeriod)
                        .padding(.horizontal)
                        .onChange(of: selectedPeriod) { _, newValue in
                            Task {
                                await viewModel.loadData(for: newValue)
                            }
                        }
                    
                    // Summary Cards
                    SummaryCardsView(
                        income: viewModel.totalIncome,
                        expense: viewModel.totalExpenses,
                        savings: viewModel.savings
                    )
                    .padding(.horizontal)
                    
                    // Chart Type Picker
                    Picker("Chart Type", selection: $selectedChart) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Chart
                    Group {
                        switch selectedChart {
                        case .pie:
                            CategoryPieChartView(data: viewModel.categoryData)
                        case .trend:
                            TrendLineChartView(data: viewModel.dailyData)
                        case .comparison:
                            ComparisonChartView(
                                currentPeriod: viewModel.totalExpenses,
                                previousPeriod: viewModel.previousPeriodExpenses
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Top Categories
                    if !viewModel.categoryData.isEmpty {
                        TopCategoriesView(categories: viewModel.categoryData)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .appBackground()
            .navigationTitle("Reports")
            .task {
                await viewModel.loadData(for: selectedPeriod)
            }
        }
    }
}

// MARK: - Report Period

enum ReportPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct ReportPeriodSelector: View {
    @Binding var selectedPeriod: ReportPeriod
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ReportPeriod.allCases, id: \.self) { period in
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

// MARK: - Summary Cards

struct SummaryCardsView: View {
    let income: Decimal
    let expense: Decimal
    let savings: Decimal
    
    var body: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Income",
                amount: income,
                color: .green,
                icon: "arrow.down.circle.fill"
            )
            
            SummaryCard(
                title: "Expense",
                amount: expense,
                color: .red,
                icon: "arrow.up.circle.fill"
            )
            
            SummaryCard(
                title: "Saved",
                amount: savings,
                color: savings >= 0 ? .blue : .orange,
                icon: "banknote.fill"
            )
        }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Decimal
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(amount.currencyFormattedCompact)
                .font(.subheadline.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Top Categories

struct TopCategoriesView: View {
    let categories: [CategoryChartData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Categories")
                .font(.headline)
            
            ForEach(categories.prefix(5)) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundStyle(item.category.color)
                        .frame(width: 24)
                    
                    Text(item.category.rawValue)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.total.currencyFormatted)
                            .font(.subheadline.bold())
                        Text("\(Int(item.percentage))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ReportsView()
        .environment(\.managedObjectContext, CoreDataManager.preview.viewContext)
}
