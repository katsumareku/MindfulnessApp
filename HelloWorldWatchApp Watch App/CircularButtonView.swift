//
//  CircularButtonView.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 04/03/2025.
//

import SwiftUI

struct CircularButtonView: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(width: 80, height: 80)
            .background(Circle().fill(color))
            .foregroundColor(.white)
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .shadow(radius: 5)
    }
}
