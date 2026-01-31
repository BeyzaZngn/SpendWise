import SwiftUI

struct BudgetView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showingAddBudget = false
    @State private var editingBudget: Budget?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.budgets.isEmpty {
                    ProgressView("Loading...")
                } else if viewModel.budgets.isEmpty {
                    EmptyBudgetView {
                        showingAddBudget = true
                    }
                } else {
                    budgetList
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBudget = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView { budget in
                    Task {
                        await viewModel.addBudget(budget)
                    }
                }
            }
            .sheet(item: $editingBudget) { budget in
                EditBudgetView(budget: budget) { updatedBudget in
                    Task {
                        await viewModel.updateBudget(updatedBudget)
                    }
                }
            }
            .task {
                await viewModel.loadBudgets()
            }
            .refreshable {
                await viewModel.loadBudgets()
            }
        }
    }
    
    private var budgetList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Overall Budget Card
                OverallBudgetCard(
                    spent: viewModel.totalSpent,
                    limit: viewModel.totalLimit,
                    progress: viewModel.overallProgress
                )
                .padding(.horizontal)
                
                // Budget Items
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.budgets) { budget in
                        BudgetItemView(budget: budget)
                            .onTapGesture {
                                editingBudget = budget
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteBudget(budget)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal)
                
                // Budget Tips
                if !viewModel.exceededBudgets.isEmpty {
                    BudgetWarningView(exceededBudgets: viewModel.exceededBudgets)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .appBackground()
    }
}

// MARK: - Overall Budget Card

struct OverallBudgetCard: View {
    let spent: Decimal
    let limit: Decimal
    let progress: Double
    
    private var progressColor: Color {
        if progress >= 1.0 { return .red }
        if progress >= 0.8 { return .orange }
        return .green
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Total Budget")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(spent.currencyFormatted)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("of \(limit.currencyFormatted)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(progressColor.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)
                
                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.title.bold())
                    Text("Used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            
            // Remaining
            HStack {
                Text("Remaining")
                    .foregroundStyle(.secondary)
                Spacer()
                Text((limit - spent).currencyFormatted)
                    .font(.subheadline.bold())
                    .foregroundStyle(progress >= 1 ? .red : .green)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Budget Item

struct BudgetItemView: View {
    let budget: Budget
    
    private var progressColor: Color {
        if budget.isExceeded { return .red }
        if budget.isNearLimit { return .orange }
        return .green
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: budget.category.icon)
                    .font(.title3)
                    .foregroundStyle(budget.category.color)
                    .frame(width: 36, height: 36)
                    .background(budget.category.color.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.category.rawValue)
                        .font(.subheadline.weight(.medium))
                    Text(budget.period.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(budget.spent.currencyFormatted)
                        .font(.subheadline.weight(.semibold))
                    Text("of \(budget.limit.currencyFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor.gradient)
                        .frame(width: min(geometry.size.width * budget.progress, geometry.size.width))
                }
            }
            .frame(height: 8)
            
            // Status
            if budget.isExceeded {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Over budget by \(abs(budget.remaining).currencyFormatted)")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                }
            } else if budget.isNearLimit {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("\(budget.remaining.currencyFormatted) remaining")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Empty State

struct EmptyBudgetView: View {
    let onAdd: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("No Budgets", systemImage: "target")
        } description: {
            Text("Create budgets to track your spending limits by category.")
        } actions: {
            Button("Create Budget", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Budget Warning

struct BudgetWarningView: View {
    let exceededBudgets: [Budget]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Budget Alerts")
                    .font(.headline)
            }
            
            ForEach(exceededBudgets) { budget in
                HStack {
                    Text(budget.category.rawValue)
                        .font(.subheadline)
                    Spacer()
                    Text("Over by \(abs(budget.limit - budget.spent).currencyFormatted)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    BudgetView()
        .environment(\.managedObjectContext, CoreDataManager.preview.viewContext)
}
