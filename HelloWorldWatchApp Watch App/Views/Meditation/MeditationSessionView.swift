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
    @State private var isSaving = false
    @State private var sessionSaved = false
    @State private var saveError: String? = nil
    @State private var showFocusRating = false
    @State private var focusRating: Int? = nil
    
    let durations = [60, 180, 300, 600] // 1, 3, 5, 10 mins in seconds
    
    var body: some View {
        VStack(spacing: 8) {
            if showFocusRating {
                // Focus rating view
                FocusRatingView(
                    rating: $focusRating,
                    onSave: {
                        saveSession(duration: selectedDuration)
                        showFocusRating = false
                    },
                    onSkip: {
                        saveSession(duration: selectedDuration)
                        showFocusRating = false
                    }
                )
        
            } else if isMeditating {
                // Active meditation session view
                MeditationTimerView(timeRemaining: $timeRemaining, selectedDuration: $selectedDuration, isMeditating: $isMeditating)
                    .padding(.vertical, 10)
                
                Spacer()
                
                Button("End Session") {
                    endMeditation()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.bottom, 10)
            } else {
                // Selection screen
                VStack(spacing: 0) {
                    if isSaving {
                        Text("Saving session...")
                            .font(.caption)
                            .foregroundColor(.gray)
                        ProgressView()
                            .padding(.bottom, 5)
                    } else if sessionSaved {
                        Text("Session saved!")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.bottom, 5)
                    } else if let error = saveError {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.bottom, 5)
                    }
                    
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
        .animation(.easeInOut, value: showFocusRating)
        .onAppear {
            resetTimer()
            
            sessionSaved = false
            saveError = nil
        }
    }
    
    func playAudio() {
        let sound = settings.currentSound
        
        if !sound.filename.isEmpty, let soundURL = Bundle.main.url(forResource: sound.filename, withExtension: sound.fileExtension) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.play()
            } catch {
                print("Error loading audio: \(error)")
            }
        } else {
            print("No sound selected or audio file not found")
        }
    }
    
    func startMeditation() {
        isMeditating = true
        timeRemaining = selectedDuration
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endMeditation()
            }
        }
        if !settings.currentSound.filename.isEmpty {
            playAudio()
        }
    }
    
    func endMeditation() {
        isMeditating = false
        timer?.invalidate()
        
        WKInterfaceDevice.current().play(.success)
        
        audioPlayer?.stop()
        showFocusRating = true
        focusRating = nil
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
    
    func saveSession(duration: Int) {
        isSaving = true
        sessionSaved = false
        saveError = nil
        
        let soundUsed = settings.currentSound.filename.isEmpty ? nil : settings.currentSound.name
        
        APIService.shared.saveMeditationSession(duration: duration, focusRating: focusRating, soundUsed: soundUsed) {
            success in DispatchQueue.main.async {
                self.isSaving = false
                
                if success {
                    self.sessionSaved = true
                    print("Successfully saved meditation session to backend")
                } else {
                    self.saveError = "Failed to save"
                    print("Failed to save meditation session")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if !self.isMeditating {
                        self.sessionSaved = false
                        self.saveError = nil
                    }
                }
            }
        }
    }
}

struct FocusRatingView: View {
    @Binding var rating: Int?
    var onSave: () -> Void
    var onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("How focused were you?")
                .font(.headline)
                .padding(.top, 5)
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button(action: {
                        rating = value
                    }) {
                        Image(systemName: rating != nil && value <= rating! ? "star.fill" : "star")
                            .foregroundColor(rating != nil && value <= rating! ? .yellow : .gray)
                            .font(.system(size: 24))
                            .frame(width: 36, height: 44)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Text(ratingDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(height: 30)
                .padding(.horizontal, 5)
            
            Spacer()
            
            HStack {
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(rating == nil)
                
                Button("Skip") {
                    onSkip()
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 10)
        }
        .navigationBarHidden(true)
    }
    
    var ratingDescription: String {
        guard let rating = rating else { return "Select a rating" }
        
        switch rating {
        case 1: return "Very distracted"
        case 2: return "Somewhat distracted"
        case 3: return "Neutral focus"
        case 4: return "Mostly focused"
        case 5: return "Deeply focused"
        default: return "Select a rating"
        }
    }
}
