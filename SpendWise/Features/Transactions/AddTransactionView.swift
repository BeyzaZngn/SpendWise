import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var transactionType: TransactionType = .expense
    @State private var amount: String = ""
    @State private var selectedCategory: Category = .food
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var isRecurring: Bool = false
    @State private var recurringInterval: RecurringInterval = .monthly
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case amount
        case note
    }
    
    var onSave: ((Transaction) -> Void)?
    
    var body: some View {
        NavigationStack {
            Form {
                // Transaction Type
                Section {
                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Amount
                Section("Amount") {
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .focused($focusedField, equals: .amount)
                            .onChange(of: amount) { _, newValue in
                                // Filter out non-numeric characters (allow digits and decimal point only)
                                let filtered = newValue.filter { $0.isNumber || $0 == "." || $0 == "," }
                                if filtered != newValue {
                                    amount = filtered
                                }
                            }
                    }
                    .padding(.vertical, 8)
                }
                
                // Category
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
                
                // Date
                Section("Date") {
                    DatePicker(
                        "Transaction Date",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                }
                
                // Note
                Section("Note") {
                    TextField("Add a note (optional)", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                        .focused($focusedField, equals: .note)
                }
                
                // Recurring
                Section {
                    Toggle(isOn: $isRecurring) {
                        Label("Recurring Transaction", systemImage: "repeat")
                    }
                    
                    if isRecurring {
                        Picker("Repeat", selection: $recurringInterval) {
                            ForEach(RecurringInterval.allCases, id: \.self) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                    .disabled(amount.isEmpty)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveTransaction() {
        guard let decimalAmount = Decimal(string: amount), decimalAmount > 0 else {
            errorMessage = "Please enter a valid amount"
            showingError = true
            return
        }
        
        let transaction = Transaction(
            amount: decimalAmount,
            type: transactionType,
            category: selectedCategory,
            date: date,
            note: note,
            isRecurring: isRecurring,
            recurringInterval: isRecurring ? recurringInterval : nil
        )
        
        onSave?(transaction)
        dismiss()
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : category.color)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? category.color : category.color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(category.rawValue)
                    .font(.caption)
                    .foregroundStyle(isSelected ? category.color : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddTransactionView()
}
