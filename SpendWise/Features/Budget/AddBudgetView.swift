import SwiftUI

struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: Category = .food
    @State private var limit: String = ""
    @State private var period: BudgetPeriod = .monthly
    
    var onSave: ((Budget) -> Void)?
    
    var body: some View {
        NavigationStack {
            Form {
                // Category Selection
                Section("Category") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Category.allCases) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Limit Amount
                Section("Budget Limit") {
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        TextField("0.00", text: $limit)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    .padding(.vertical, 8)
                }
                
                // Period
                Section("Period") {
                    Picker("Budget Period", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                    .fontWeight(.semibold)
                    .disabled(limit.isEmpty)
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let decimalLimit = Decimal(string: limit), decimalLimit > 0 else {
            return
        }
        
        let budget = Budget(
            category: selectedCategory,
            limit: decimalLimit,
            period: period
        )
        
        onSave?(budget)
        dismiss()
    }
}

// MARK: - Edit Budget View

struct EditBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    
    let budget: Budget
    @State private var limit: String
    @State private var period: BudgetPeriod
    
    var onSave: ((Budget) -> Void)?
    
    init(budget: Budget, onSave: ((Budget) -> Void)? = nil) {
        self.budget = budget
        self.onSave = onSave
        _limit = State(initialValue: "\(budget.limit)")
        _period = State(initialValue: budget.period)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Category (read-only)
                Section("Category") {
                    HStack {
                        Image(systemName: budget.category.icon)
                            .foregroundStyle(budget.category.color)
                            .font(.title2)
                        Text(budget.category.rawValue)
                            .font(.headline)
                    }
                }
                
                // Current Status
                Section("Current Status") {
                    HStack {
                        Text("Spent")
                        Spacer()
                        Text(budget.spent.currencyFormatted)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Progress")
                        Spacer()
                        Text("\(Int(budget.progress * 100))%")
                            .foregroundStyle(budget.isExceeded ? .red : (budget.isNearLimit ? .orange : .green))
                            .fontWeight(.semibold)
                    }
                }
                
                // Edit Limit
                Section("Budget Limit") {
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        TextField("0.00", text: $limit)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    .padding(.vertical, 8)
                }
                
                // Period
                Section("Period") {
                    Picker("Budget Period", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(limit.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let decimalLimit = Decimal(string: limit), decimalLimit > 0 else {
            return
        }
        
        var updatedBudget = budget
        updatedBudget.limit = decimalLimit
        updatedBudget.period = period
        
        onSave?(updatedBudget)
        dismiss()
    }
}

#Preview {
    AddBudgetView()
}
