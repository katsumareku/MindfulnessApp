//
//  CustomDurationPickerView.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import SwiftUI

struct CustomDurationPickerView: View {
    @Binding var selectedDuration: Int
    let startMeditation: () -> Void
    @State private var customDuration: Double = 1
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            Text("Select Duration")
                .font(.headline)
                .padding(.top)
            
            ZStack {
                CircularProgressView(
                    progress: customDuration > 1 ? customDuration / 60 : 0.0,
                    size: 120, lineWidth: 5, color: .blue)
                
                Text("\(Int(customDuration)) min")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(Circle().fill(Color.blue))
                    .focusable(true)
                    .digitalCrownRotation($customDuration, from: 1, through: 60, sensitivity: .low)
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
