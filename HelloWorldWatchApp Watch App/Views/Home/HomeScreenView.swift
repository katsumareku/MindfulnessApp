//
//  HomeScreenView.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 09/03/2025.
//

import SwiftUI

struct HomeScreenView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome")
                    .font(.title3)
                    .padding()
                
                NavigationLink("Meditate", destination: MeditationSessionView())
                    .padding()
                    .buttonStyle(.borderedProminent)
                
                NavigationLink("History", destination: HistoryView())
                    .padding()
                    .buttonStyle(.bordered)
                NavigationLink("Settings", destination: SettingsView())
                    .padding()
                    .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    HomeScreenView()
}
