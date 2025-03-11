//
//  CircularProgressView.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 05/03/2025.
//

import SwiftUI

struct CircularProgressView: View {
    var progress: CGFloat
    var size: CGFloat
    var lineWidth: CGFloat
    var color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
        .frame(width: size, height: size)
    }
}
