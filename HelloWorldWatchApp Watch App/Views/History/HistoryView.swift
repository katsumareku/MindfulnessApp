import SwiftUI
import Charts

struct HistoryView: View {
    @State private var progressData: ProgressResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Retry") {
                    loadHistory()
                }
            } else if let data = progressData, !data.days.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        chartView
                            .padding(.horizontal, 5)
                            .padding(.bottom, 5)
                            .background(Color.clear)

                        summaryStats
                    }
                }
                .navigationTitle("History")
            } else {
                Text("No meditation history found")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadHistory()
        }
    }

    private var chartView: some View {
        let filteredData = filterDataForWeek()

        return Chart(filteredData) { day in
            BarMark(
                x: .value("Date", formatShortDate(day.date)),
                y: .value("Minutes", day.totalSeconds / 60)
            )
            .foregroundStyle(day.goalCompleted ? Color.green : Color.blue)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let strValue = value.as(String.self) {
                        Text(strValue)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 140)
        .clipShape(Rectangle())
    }

    private var summaryStats: some View {
        let filteredData = filterDataForWeek()
        let totalSessions = filteredData.reduce(0) { $0 + $1.sessions.count }
        let totalMinutes = filteredData.reduce(0) { $0 + $1.totalSeconds / 60 }
        let averageRating = calculateAverageRating(filteredData)

        return VStack(spacing: 8) {
            Text("Summary").font(.footnote)
                .padding(.top, 5)

            HStack(spacing: 12) {
                StatView(title: "Sessions", value: "\(totalSessions)")
                StatView(title: "Minutes", value: "\(totalMinutes)")
                if let rating = averageRating {
                    StatView(title: "Avg. Focus", value: String(format: "%.1f", rating))
                }
            }
            .padding(.horizontal, 5)
        }
        .padding(.bottom, 5)
        .background(Color.clear)
    }

    private func filterDataForWeek() -> [DayProgress] {
        guard let data = progressData else { return [] }

        let sortedDays = sortedDays(data.days)
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return sortedDays.filter { day in
            if let date = parseDate(day.date) {
                return date >= oneWeekAgo
            }
            return false
        }
    }

    private func calculateAverageRating(_ days: [DayProgress]) -> Double? {
        var totalRating = 0.0
        var ratedSessions = 0

        for day in days {
            for session in day.sessions {
                if let rating = session.focusRating {
                    totalRating += Double(rating)
                    ratedSessions += 1
                }
            }
        }

        return ratedSessions > 0 ? totalRating / Double(ratedSessions) : nil
    }

    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString)
    }

    private func formatShortDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "d"
            return dateFormatter.string(from: date)
        }

        return dateString
    }

    private func sortedDays(_ days: [DayProgress]) -> [DayProgress] {
        return days.sorted { $0.date < $1.date }
    }

    private func loadHistory() {
        isLoading = true
        errorMessage = nil

        APIService.shared.getProgressData { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let data):
                    self.progressData = data
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
        }
    }
}
