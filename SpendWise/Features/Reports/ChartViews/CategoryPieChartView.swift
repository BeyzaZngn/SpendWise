import SwiftUI
import Charts

struct CategoryPieChartView: View {
    let data: [CategoryChartData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.headline)
            
            if data.isEmpty {
                Text("No expense data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: item.total).doubleValue),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(item.category.color.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 250)
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let frame = chartProxy.plotFrame {
                            VStack {
                                Text("Total")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(totalAmount.currencyFormatted)
                                    .font(.title2.bold())
                            }
                            .position(x: geometry[frame].midX, y: geometry[frame].midY)
                        }
                    }
                }
                
                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(data) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 10, height: 10)
                            Text(item.category.rawValue)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(item.percentage))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var totalAmount: Decimal {
        data.reduce(0) { $0 + $1.total }
    }
}

#Preview {
    CategoryPieChartView(data: CategoryChartData.sampleData)
        .padding()
}
