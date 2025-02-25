//
//  ContentView.swift
//  HelloWorldWatchApp Watch App
//
//  Created by Jacek Kaczmarek on 13/11/2024.
//

import SwiftUI

struct HomeScreenView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome")
                    .font(.title)
                    .padding()
                
                NavigationLink("Start Meditation", destination: MeditationSessionView())
                    .padding()
                    .buttonStyle(.borderedProminent)
                
                NavigationLink("History", destination: HistoryView())
                    .padding()
                    .buttonStyle(.bordered)
            }
        }
    }
}

struct MeditationSessionView: View {
    @State private var timeRemaining = 60
    @State private var isMeditating = false
    @State private var timer: Timer?
    @State private var selectedDuration = 60
    let durations = [60, 180, 300, 600] // 1, 3, 5, 10 mins in seconds

    var body: some View {
        VStack {
            if isMeditating {
                MeditationTimerView(timeRemaining: $timeRemaining, selectedDuration: $selectedDuration, isMeditating: $isMeditating)

                Button("End Session") {
                    stopMeditation()
                }
                .padding()
                .buttonStyle(.bordered)
            } else {
                DurationPickerView(selectedDuration: $selectedDuration)

                Button("Start Session") {
                    startMeditation()
                }
                .padding()
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            resetTimer()
        }
        .padding(.top, 20)
    }

    func startMeditation() {
        isMeditating = true
        timeRemaining = selectedDuration
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopMeditation()
            }
        }
    }

    func stopMeditation() {
        isMeditating = false
        timer?.invalidate()
        
        WKInterfaceDevice.current().play(.success)
        
        saveSession(duration: selectedDuration)
    }

    func resetTimer() {
        stopMeditation()
        timeRemaining = selectedDuration
    }
}

struct MeditationTimerView: View {
    @Binding var timeRemaining: Int
    @Binding var selectedDuration: Int
    @Binding var isMeditating: Bool
    
    var body: some View {
        VStack {
            if isMeditating {
                Text("Time Remaining: \(formatTime(timeRemaining))")
                    .font(.headline)
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 10)
                    
                    Circle()
                        .trim(from: 0, to: 1 - (CGFloat(timeRemaining) / CGFloat(selectedDuration)))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)
                }
                    .frame(width: 100, height: 100)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

struct DurationPickerView: View {
    @Binding var selectedDuration: Int
    
    var body: some View {
        VStack {
            Text("Select Session Length")
                .font(.headline)
            
            Picker("Duration", selection: $selectedDuration) {
                Text("1 min").tag(60)
                Text("3 min").tag(180)
                Text("5 min").tag(300)
                Text("10 min").tag(600)
            }
            .frame(height: 80)
            .pickerStyle(.wheel)
        }
    }
}

func formatTime(_ seconds: Int) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = .pad
    return formatter.string(from: TimeInterval(seconds)) ?? "0:00"
}

func saveSession(duration: Int) {
    var history = UserDefaults.standard.array(forKey: "meditationHistory") as? [Int] ?? []
    history.append(duration)
    UserDefaults.standard.set(history, forKey: "meditationHistory")
}

struct HistoryView: View {
    let history = UserDefaults.standard.array(forKey: "meditationHistory") as? [Int] ?? []
    var body: some View {
        List(history, id: \.self) { session in
            Text(formatTime(session))
        }
        .navigationTitle("History")
    }
}

#Preview {
    HomeScreenView()
}
