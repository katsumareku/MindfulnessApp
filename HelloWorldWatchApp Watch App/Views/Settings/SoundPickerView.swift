//
//  SoundPickerView.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import SwiftUI

struct SoundPickerView: View {
    @ObservedObject var settings: MeditationSettings
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            ForEach(0..<settings.availableSounds.count, id: \.self) { index in
                Button(action: {
                    settings.selectedSoundIndex = index
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(settings.availableSounds[index].name)
                        Spacer()
                        if index == settings.selectedSoundIndex {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Choose Sound")
    }
}

