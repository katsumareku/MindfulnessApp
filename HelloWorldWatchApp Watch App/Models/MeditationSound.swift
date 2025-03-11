//
//  MeditationSound.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import Foundation

struct MeditationSound: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let filename: String
    let fileExtension: String
}
