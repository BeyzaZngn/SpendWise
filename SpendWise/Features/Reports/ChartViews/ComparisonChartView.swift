import SwiftUI
import Charts

struct ComparisonChartView: View {
    let currentPeriod: Decimal
    let previousPeriod: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Period Comparison")
                .font(.headline)
            
            Chart {
                BarMark(
                    x: .value("Period", "Previous"),
                    y: .value("Amount", NSDecimalNumber(decimal: previousPeriod).doubleValue)
                )
                .foregroundStyle(Color.gray.gradient)
                .cornerRadius(8)
                
                BarMark(
                    x: .value("Period", "Current"),
                    y: .value("Amount", NSDecimalNumber(decimal: currentPeriod).doubleValue)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(8)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(Decimal(amount).currencyFormattedCompact)
                                .font(.caption)
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 200)
            
            // Comparison Summary
            HStack(spacing: 20) {
                ComparisonItem(
                    title: "Previous Period",
                    amount: previousPeriod,
                    color: .gray
                )
                
                ComparisonItem(
                    title: "Current Period",
                    amount: currentPeriod,
                    color: .accentColor
                )
            }
            
            // Change Indicator
            changeIndicator
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var changeIndicator: some View {
        let change = currentPeriod - previousPeriod
        let percentChange: Double = previousPeriod > 0
            ? NSDecimalNumber(decimal: (change / previousPeriod) * 100).doubleValue
            : 0
        
        HStack {
            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                .foregroundStyle(change >= 0 ? .red : .green)
            
            Text(change >= 0 ? "Spent more" : "Saved")
                .font(.subheadline)
            
            Text(abs(change).currencyFormatted)
                .font(.subheadline.bold())
            
            Text("(\(String(format: "%.1f", abs(percentChange)))%)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            (change >= 0 ? Color.red : Color.green).opacity(0.1),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}

struct ComparisonItem: View {
    let title: String
    let amount: Decimal
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(amount.currencyFormatted)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ComparisonChartView(currentPeriod: 1500, previousPeriod: 1200)
        .padding()
}
