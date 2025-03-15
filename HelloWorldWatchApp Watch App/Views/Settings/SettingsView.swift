import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = MeditationSettings()
    @State private var isLoading = true
    @State private var dailyGoalMinutes: Int = 10
    @State private var daysPerWeek: Int = 5
    
    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                }
            } else {
                NavigationLink(destination: MeditationGoalsView()) {
                    HStack {
                        Text("Meditation Goals")
                        Spacer()
                        Text("\(dailyGoalMinutes) min, \(daysPerWeek) days/week")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                
                NavigationLink(destination: SoundPickerView(settings: settings)) {
                    HStack {
                        Text("Default Sound")
                        Spacer()
                        Text(settings.currentSound.name)
                            .foregroundColor(.gray)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                
                Section(header: Text("Display")) {
                    Toggle("Dark Mode", isOn: .constant(false))
                        .disabled(true)
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Session Reminders", isOn: .constant(false))
                        .disabled(true)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear(perform: loadGoals)
    }
    
    private func loadGoals() {
        isLoading = true
        
        APIService.shared.getMeditationGoal { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let goalResponse):
                    self.dailyGoalMinutes = goalResponse.dailyMinutes
                    self.daysPerWeek = goalResponse.daysPerWeek
                case .failure:
                    // Use default values if goals can't be loaded
                    self.dailyGoalMinutes = 10
                    self.daysPerWeek = 5
                }
            }
        }
    }
}

struct MeditationGoalsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var dailyGoalMinutes: Int = 10
    @State private var daysPerWeek: Int = 5
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var hasExistingGoals = false
    
    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading goals...")
                    Spacer()
                }
            } else {
                Section(header: Text("Daily Goal")) {
                    HStack {
                        Text("\(dailyGoalMinutes) minutes")
                        Spacer()
                        Stepper("", value: $dailyGoalMinutes, in: 1...120)
                            .labelsHidden()
                    }
                }
                
                Section(header: Text("Weekly Goal")) {
                    HStack {
                        Text("\(daysPerWeek) days per week")
                        Spacer()
                        Stepper("", value: $daysPerWeek, in: 1...7)
                            .labelsHidden()
                    }
                }
                
                Section {
                    Button(action: saveGoals) {
                        HStack {
                            Spacer()
                            Text(hasExistingGoals ? "Update Goals" : "Create Goals")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                    
                    if isSaving {
                        HStack {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Meditation Goals")
        .onAppear(perform: loadGoals)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Meditation Goals"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("successfully") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
    
    private func loadGoals() {
        isLoading = true
        
        APIService.shared.getMeditationGoal { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let goalResponse):
                    self.dailyGoalMinutes = goalResponse.dailyMinutes
                    self.daysPerWeek = goalResponse.daysPerWeek
                    self.hasExistingGoals = true
                case .failure:
                    // Use default values if goals can't be loaded
                    self.dailyGoalMinutes = 10
                    self.daysPerWeek = 5
                    self.hasExistingGoals = false
                }
            }
        }
    }
    
    private func saveGoals() {
        isSaving = true
        
        APIService.shared.registerDevice { result in
            switch result {
            case .success(let userId):
                // Now save the goals using the user_id
                guard let url = URL(string: "http://localhost:5001/api/goals/goals") else {
                    handleSaveError(NSError(domain: "GoalsAPIHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "user_id": userId,
                    "daily_minutes": dailyGoalMinutes,
                    "days_per_week": daysPerWeek
                ]
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async {
                        self.isSaving = false
                        
                        if let error = error {
                            self.handleSaveError(error)
                            return
                        }
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            self.handleSaveError(NSError(domain: "GoalsAPIHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                            return
                        }
                        
                        if (200...299).contains(httpResponse.statusCode) {
                            self.alertMessage = self.hasExistingGoals ? "Goals updated successfully" : "Goals created successfully"
                            self.hasExistingGoals = true
                            self.showingAlert = true
                        } else {
                            var errorMessage = "Server error: \(httpResponse.statusCode)"
                            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let message = json["message"] as? String {
                                errorMessage = message
                            }
                            
                            self.handleSaveError(NSError(domain: "GoalsAPIHelper", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                        }
                    }
                }.resume()
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.handleSaveError(error)
                }
            }
        }
    }
    
    private func handleSaveError(_ error: Error) {
        isSaving = false
        alertMessage = "Failed to save goals: \(error.localizedDescription)"
        showingAlert = true
    }
}
