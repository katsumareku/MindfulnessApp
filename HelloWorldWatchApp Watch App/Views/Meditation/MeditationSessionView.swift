//
//  MeditationSessionView.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import SwiftUI
import AVFoundation

struct MeditationSessionView: View {
    @State private var timeRemaining = 60
    @State private var isMeditating = false
    @State private var timer: Timer?
    @State private var selectedDuration = 60
    @State private var audioPlayer: AVAudioPlayer?
    @State private var selectedSoundIndex = 0
    @StateObject private var settings = MeditationSettings()
    @State private var showingSoundPicker = false
    
    let durations = [60, 180, 300, 600] // 1, 3, 5, 10 mins in seconds
    
    var body: some View {
        VStack(spacing: 8) {
            if isMeditating {
                // Active meditation session view
                MeditationTimerView(timeRemaining: $timeRemaining, selectedDuration: $selectedDuration, isMeditating: $isMeditating)
                    .padding(.vertical, 10)
                
                Spacer()
                
                Button("End Session") {
                    stopMeditation()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.bottom, 10)
            } else {
                // Selection screen
                // Selection screen
                VStack(spacing: 0) {
                    // Duration picker section
                    DurationPickerView(
                        selectedDuration: $selectedDuration,
                        startMeditation: startMeditation,
                        settings: settings
                    )
                }
            }
        }
        .animation(.easeInOut, value: isMeditating)
        .onAppear {
            resetTimer()
        }
    }
    func playAudio() {
        let sound = settings.currentSound
        
        if let soundURL = Bundle.main.url(forResource: sound.filename, withExtension: sound.fileExtension) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.play()
            } catch {
                print("Error loading audio: \(error)")
            }
        } else {
            print("Audio file not found: \(sound.filename).\(sound.fileExtension)")
        }
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
        playAudio()
    }
    
    func stopMeditation() {
        isMeditating = false
        timer?.invalidate()
        
        WKInterfaceDevice.current().play(.success)
        
        saveSession(duration: selectedDuration)
        audioPlayer?.stop()
    }
    
    func resetTimer() {
        if !isMeditating {
            timeRemaining = selectedDuration
        }
    }
}
