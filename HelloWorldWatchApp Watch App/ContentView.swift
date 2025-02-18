//
//  ContentView.swift
//  HelloWorldWatchApp Watch App
//
//  Created by Jacek Kaczmarek on 13/11/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var timeRemaining = 60
    @State private var isMeditating = false
    @State private var timer: Timer?

    var body: some View {
        VStack {
            if isMeditating {
                Text("Time Remaining: \(timeRemaining)")
                    .font(.headline)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 10)
                    
                    Circle()
                        .trim(from: 0, to: 1 - (CGFloat(timeRemaining) / 60))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)
                }
                    .frame(width: 100, height: 100)

                Button("End Session") {
                    stopMeditation()
                }
                .padding()
                .buttonStyle(.bordered)
            } else {
                Text("Welcome")
                    .font(.title)
                    .padding()

                Button("Start 1-Minute Session") {
                    startMeditation()
                }
                .padding()
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            resetTimer()
        }
        .padding()
    }

    func startMeditation() {
        isMeditating = true
        timeRemaining = 60
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
    }

    func resetTimer() {
        stopMeditation()
        timeRemaining = 60
    }
}

#Preview {
    ContentView()
}
