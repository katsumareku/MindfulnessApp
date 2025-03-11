//
//  HistoryView.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import SwiftUI

struct HistoryView: View {
    let history = UserDefaults.standard.array(forKey: "meditationHistory") as? [Int] ?? []
    var body: some View {
        List(history, id: \.self) { session in
            Text(formatTime(session))
        }
        .navigationTitle("History")
    }
}
