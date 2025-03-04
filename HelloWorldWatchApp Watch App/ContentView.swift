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
                
                NavigationLink("Meditate", destination: MeditationSessionView())
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
                DurationPickerView(selectedDuration: $selectedDuration, startMeditation: startMeditation)
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
        if !isMeditating {
            timeRemaining = selectedDuration
        }
    }
}

struct MeditationTimerView: View {
    @Binding var timeRemaining: Int
    @Binding var selectedDuration: Int
    @Binding var isMeditating: Bool
    
    var body: some View {
        VStack {
            if isMeditating {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 10)
                    
                    Circle()
                        .trim(from: 0, to: 1 - (CGFloat(timeRemaining) / CGFloat(selectedDuration)))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)
                    
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                    .frame(width: 100, height: 100)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

struct DurationPickerView: View {
    @Binding var selectedDuration: Int
    let startMeditation: () -> Void
    
    let durations = [60, 180, 300, 600, 900]
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding([.top, .trailing], 5)
            
            GeometryReader { geometry in
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        
                        NavigationLink(destination: CustomDurationPickerView(selectedDuration: $selectedDuration, startMeditation: startMeditation)) {
                                                    Text("Custom")
                                                        .font(.headline)
                                                        .frame(width: 80, height: 80)
                                                        .background(Circle().fill(Color.gray))
                                                        .foregroundColor(.white)
                                                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                                        .shadow(radius: 5)
                        }
                        
                        ForEach(durations, id: \.self) { duration in
                            Button(action: {
                                selectedDuration = duration
                                startMeditation()
                            }) {
                                Text(formatTime(duration))
                                    .font(.headline)
                                    .frame(width: 80, height: 80)
                                    .background(Circle().fill(Color.blue))
                                    .foregroundColor(.white)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                    .shadow(radius: 5)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .focused($isFocused)
            }
            .frame(height: 180)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, -20)
        .onAppear {
            isFocused = true
        }
    }
}

struct CustomDurationPickerView: View {
    @Binding var selectedDuration: Int
    let startMeditation: () -> Void
    @State private var customDuration: Double = 1 // Default start duration
    @FocusState private var isFocused: Bool // Enables Digital Crown control
    
    var body: some View {
        VStack {
            Text("Select Duration")
                .font(.headline)
                .padding(.top)
            
            ZStack {
                Circle()
                    .stroke(Color.blue, lineWidth: 5)
                    .frame(width: 120, height: 120)
                
                Text("\(Int(customDuration)) min")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(Circle().fill(Color.blue))
                    .focusable(true)
                    .digitalCrownRotation($customDuration, from: 1, through: 60, by: 1.0)
                    .focused($isFocused)
            }
            .onAppear { isFocused = true }
            
            Spacer()
            
            Button("Start Meditation") {
                selectedDuration = Int(customDuration) * 60
                startMeditation()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
