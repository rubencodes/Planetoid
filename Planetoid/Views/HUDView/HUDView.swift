//
//  HUDView.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/18/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct HUDView: View {

    // MARK: - Internal Properties

    @Binding var state: GameState
    let score: Int
    let health: [Int]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ScoreView(score: score)

                Spacer(minLength: 0)

                HealthView(health: health)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer(minLength: 0)

                if case .play(let level) = state {
                    Button {
                        state = .pause(level: level)
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(.icon)
                } else if case .pause(let level) = state {
                    Button {
                        state = .play(level: level)
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                            .offset(x: 2)
                    }
                    .buttonStyle(.icon)
                }
            }
            .sensoryFeedback(.start, trigger: state) { _, newValue in
                guard case .play = newValue else { return false }
                return true
            }
            .sensoryFeedback(.stop, trigger: state) { _, newValue in
                guard case .pause = newValue else { return false }
                return true
            }
        }
        .padding(12)
        .background {
            if case .pause = state {
                Color.black.opacity(0.8)
            }
        }
    }
}

#Preview {
    HUDView(state: .constant(.pause(level: 1)),
            score: 50,
            health: [1, 2, 3, 4, 5, 6, 7, 8])
}
