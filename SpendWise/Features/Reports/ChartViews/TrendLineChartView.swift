import SwiftUI
import Charts

struct TrendLineChartView: View {
    let data: [DailyChartData]
    @State private var selectedDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.headline)
            
            if data.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(data) { item in
                    // Area
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", NSDecimalNumber(decimal: item.expense).doubleValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.3), .accentColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    // Line
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", NSDecimalNumber(decimal: item.expense).doubleValue)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                    // Points
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", NSDecimalNumber(decimal: item.expense).doubleValue)
                    )
                    .foregroundStyle(Color.accentColor)
                    .symbolSize(selectedDate == item.date ? 100 : 30)
                }
                .chartXSelection(value: $selectedDate)
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
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: data.count > 14 ? 7 : 1)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.shortDateString)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 200)
                
                // Selected Date Info
                if let selectedDate = selectedDate,
                   let item = data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.date.fullDateString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.expense.currencyFormatted)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TrendLineChartView(data: DailyChartData.sampleData)
        .padding()
}
