//
//  Helpers.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import Foundation
import SwiftUI

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
