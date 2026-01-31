import SwiftUI

struct TransactionListView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @State private var showingAddTransaction = false
    @State private var searchText = ""
    @State private var selectedFilter: TransactionType? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    ProgressView("Loading...")
                } else if viewModel.transactions.isEmpty {
                    EmptyStateView()
                } else {
                    transactionList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appBackground()
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All") {
                            selectedFilter = nil
                        }
                        Button("Income") {
                            selectedFilter = .income
                        }
                        Button("Expense") {
                            selectedFilter = .expense
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView { transaction in
                    Task {
                        await viewModel.addTransaction(transaction)
                    }
                }
            }
            .task {
                await viewModel.loadTransactions()
            }
            .refreshable {
                await viewModel.loadTransactions()
            }
        }
    }
    
    private var transactionList: some View {
        List {
            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                Section {
                    ForEach(groupedTransactions[date] ?? []) { transaction in
                        TransactionListRowView(transaction: transaction)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteTransaction(transaction)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(formatSectionDate(date))
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private var filteredTransactions: [Transaction] {
        var transactions = viewModel.transactions
        
        if let filter = selectedFilter {
            transactions = transactions.filter { $0.type == filter }
        }
        
        if !searchText.isEmpty {
            transactions = transactions.filter {
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.note.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return transactions
    }
    
    private var groupedTransactions: [Date: [Transaction]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.fullDateString
        }
    }
}

// MARK: - Transaction List Row

struct TransactionListRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundStyle(transaction.category.color)
                .frame(width: 40, height: 40)
                .background(transaction.category.color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category.rawValue)
                    .font(.body.weight(.medium))
                
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.type == .income
                     ? "+\(transaction.amount.currencyFormatted)"
                     : "-\(transaction.amount.currencyFormatted)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(transaction.type == .income ? .green : .primary)
                
                if transaction.isRecurring {
                    Label("Recurring", systemImage: "repeat")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Transactions", systemImage: "creditcard")
        } description: {
            Text("Start tracking your spending by adding your first transaction.")
        } actions: {
            NavigationLink {
                AddTransactionView()
            } label: {
                Text("Add Transaction")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    TransactionListView()
        .environment(\.managedObjectContext, CoreDataManager.preview.viewContext)
}
