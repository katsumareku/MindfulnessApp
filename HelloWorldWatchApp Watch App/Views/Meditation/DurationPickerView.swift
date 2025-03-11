//
//  DurationPickerView.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import SwiftUI

struct DurationPickerView: View {
    @Binding var selectedDuration: Int
    let startMeditation: () -> Void
    @ObservedObject var settings: MeditationSettings
    
    let durations = [60, 180, 300, 600, 900]
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            NavigationLink(destination: SoundPickerView(settings: settings)) {
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 12))
                    Text(settings.currentSound.name)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.blue.opacity(0.7))
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.2))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            
            // Duration section
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
                            CircularButtonView(title: "Custom", color: .gray)
                        }
                        
                        ForEach(durations, id: \.self) { duration in
                            Button(action: {
                                selectedDuration = duration
                                startMeditation()
                            }) {
                                CircularButtonView(title: formatTime(duration), color: .blue)
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
        .padding(.top, 0)
        .onAppear {
            isFocused = true
        }
    }
}
