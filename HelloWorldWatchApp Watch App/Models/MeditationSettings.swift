//
//  MeditationSettings.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import Foundation
import SwiftUI

class MeditationSettings: ObservableObject {
    @Published var selectedSoundIndex: Int {
        didSet {
            UserDefaults.standard.set(selectedSoundIndex, forKey: "selectedSoundIndex")
        }
    }
    
    let availableSounds = [
        MeditationSound(name: "No Sound", filename: "", fileExtension: ""),
        MeditationSound(name: "White Waterfall", filename: "whiteWaterfallNoise", fileExtension: "mp3"),
        MeditationSound(name: "Ocean Waves", filename: "oceanWaves", fileExtension: "mp3"),
        MeditationSound(name: "Rain", filename: "rainSound", fileExtension: "mp3"),
    ]
    
    var currentSound: MeditationSound {
        availableSounds[selectedSoundIndex]
    }
    
    init() {
        self.selectedSoundIndex = UserDefaults.standard.integer(forKey: "selectedSoundIndex")
        if self.selectedSoundIndex >= availableSounds.count {
            self.selectedSoundIndex = 0
        }
    }
}
