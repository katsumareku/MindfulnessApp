//
//  MeditationTimerView.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import SwiftUI

struct MeditationTimerView: View {
    @Binding var timeRemaining: Int
    @Binding var selectedDuration: Int
    @Binding var isMeditating: Bool
    
    var body: some View {
        VStack {
            if isMeditating {
                ZStack {
                    CircularProgressView(progress: 1 - (CGFloat(timeRemaining) / CGFloat(selectedDuration)), size: 100, lineWidth: 10, color: .blue)
                    
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
