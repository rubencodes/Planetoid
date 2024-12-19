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
                        Image(systemName: "pause.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(12)
                            .foregroundStyle(.primaryForeground)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .sensoryFeedback(.start, trigger: state)
                } else if case .pause(let level) = state {
                    Button {
                        state = .play(level: level)
                    } label: {
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .offset(x: 2)
                            .padding(12)
                            .foregroundStyle(.primaryForeground)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .sensoryFeedback(.stop, trigger: state)
                }
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
