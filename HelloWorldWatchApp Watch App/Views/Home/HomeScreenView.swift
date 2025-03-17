import SwiftUI

struct HomeScreenView: View {
    @State private var dailyProgress: Float = 0.0
    @State private var dailyGoalMinutes: Int = 20 // Default fallback value
    @State private var todaysMeditationMinutes: Int = 0
    @State private var currentStreak: Int = 0
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    // Progress Section
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 90, height: 90)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(dailyProgress))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .green]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: dailyProgress)
                        
                        VStack(spacing: 0) {
                            Text("\(todaysMeditationMinutes)")
                                .font(.system(size: 20, weight: .bold))
                            Text("/ \(dailyGoalMinutes)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text("\(currentStreak) day streak")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 5)
                }
                
                NavigationLink(destination: MeditationSessionView()) {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                        Text("Meditate")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal, 5)
                
                HStack(spacing: 6) {
                    NavigationLink(destination: HistoryView()) {
                        VStack(spacing: 2) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 14))
                            Text("Stats")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    
                    NavigationLink(destination: SettingsView()) {
                        VStack(spacing: 2) {
                            Image(systemName: "gear")
                                .font(.system(size: 14))
                            Text("Settings")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 5)
            }
            .padding(8)
            .onAppear {
                loadData()
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Connection Error"),
                    message: Text(errorMessage ?? "Could not load meditation data. Using default values instead."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        // Load cached values first
        let cachedGoal = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        if cachedGoal > 0 {
            dailyGoalMinutes = cachedGoal
        }
        
        // Try to get cached meditation minutes for today
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = "meditation_minutes_" + dateFormatter.string(from: Date())
        let cachedMinutes = UserDefaults.standard.integer(forKey: todayKey)
        if cachedMinutes > 0 {
            todaysMeditationMinutes = cachedMinutes
            dailyProgress = min(Float(todaysMeditationMinutes) / Float(dailyGoalMinutes), 1.0)
        }
        
        // Check connection before loading from API
        APIService.shared.checkServerConnection { isConnected in
            if !isConnected {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to connect to meditation server."
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            if APIService.shared.userId == nil {
                APIService.shared.registerDevice { result in
                    switch result {
                    case .success(let userId):
                        print("Successfully registered with userId: \(userId)")
                        self.fetchGoalAndProgressData(dateFormatter: dateFormatter, todayKey: todayKey)
                    case .failure(let error):
                        DispatchQueue.main.async {
                            print("Registration error: \(error.localizedDescription)")
                            self.errorMessage = "Unable to register device."
                            self.showError = true
                            self.isLoading = false
                        }
                    }
                }
            } else {
                self.fetchGoalAndProgressData(dateFormatter: dateFormatter, todayKey: todayKey)
            }
        }
    }

    func fetchGoalAndProgressData(dateFormatter: DateFormatter, todayKey: String) {
        APIService.shared.getMeditationGoal { result in
            switch result {
            case .success(let goalData):
                print("Goal Data: \(goalData)")
                UserDefaults.standard.set(goalData.dailyMinutes, forKey: "dailyGoalMinutes")
                
                DispatchQueue.main.async {
                    self.dailyGoalMinutes = goalData.dailyMinutes
                }
                
                // Now fetch progress data
                self.fetchProgressData(dateFormatter: dateFormatter, todayKey: todayKey)
                
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Goal fetch error: \(error.localizedDescription)")
                    self.errorMessage = "Unable to load goal data."
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }

    func fetchProgressData(dateFormatter: DateFormatter, todayKey: String) {
        APIService.shared.getProgressData { progressResult in
            DispatchQueue.main.async {
                switch progressResult {
                case .success(let progressData):
                    print("Progress Data: \(progressData)")
                    self.currentStreak = progressData.currentStreak
                    
                    // Get today's date in the format of the API response
                    let todayString = dateFormatter.string(from: Date())
                    
                    // Get today's progress
                    if let today = progressData.days.first(where: { day in
                        return day.date == todayString
                    }) {
                        self.todaysMeditationMinutes = today.totalSeconds / 60
                        UserDefaults.standard.set(self.todaysMeditationMinutes, forKey: todayKey)
                        self.dailyProgress = min(Float(today.totalSeconds) / Float(self.dailyGoalMinutes * 60), 1.0)
                    }
                    
                case .failure(let error):
                    print("Progress fetch error: \(error.localizedDescription)")
                    self.errorMessage = "Unable to load your progress data."
                    self.showError = true
                }
                self.isLoading = false
            }
        }
    }
    }


#Preview {
    HomeScreenView()
}
