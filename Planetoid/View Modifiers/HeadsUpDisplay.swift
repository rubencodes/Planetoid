//
//  HeadsUpDisplay.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct HeadsUpDisplay: ViewModifier {

    // MARK: - Nested Types

    enum LifeGained: String, CaseIterable {
        case nice = "Nice!"
        case woo = "Woo!"
        case rad = "Rad!"
    }

    enum LifeLost: String, CaseIterable {
        case ohNo = "Oh no!"
        case oof = "Oof!"
        case ouch = "Ouch!"
        case yikes = "Yikes!"
    }

    // MARK: - Internal Properties

    @Binding var state: GameState
    let score: Int
    let health: [Int]

    // MARK: - Private Properties

    @State private var levelMessage: String?
    @State private var overlayMessage: String?

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        renderScore()

                        Spacer(minLength: 0)

                        renderHealth()
                    }

                    Spacer(minLength: 0)

                    HStack {
                        Spacer(minLength: 0)

                        renderPlayPause()
                    }
                }
                .padding(12)
            }
            .overlay {
                if let overlayMessage {
                    Text(overlayMessage)
                        .font(.appTitle)
                        .foregroundColor(.primaryForeground)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .overlay {
                if let levelMessage {
                    Text(levelMessage)
                        .font(.appTitle)
                        .foregroundColor(.primaryForeground)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .onChange(of: state.level, initial: true) {
                withAnimation(.spring) {
                    levelMessage = "LEVEL \(state.level)"
                } completion: {
                    withAnimation(.spring.delay(0.5)) {
                        levelMessage = nil
                    }
                }
            }
            .onChange(of: health) { oldValue, newValue in
                withAnimation(.spring) {
                    if oldValue.count < newValue.count {
                        overlayMessage = LifeGained.allCases.randomElement()?.rawValue
                    } else {
                        overlayMessage = LifeLost.allCases.randomElement()?.rawValue
                    }
                } completion: {
                    withAnimation(.spring.delay(0.5)) {
                        overlayMessage = nil
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
    }

    // MARK: - Private Functions

    private func renderScore() -> some View {
        Text(String(format: "%05d", score))
            .font(.appTitleSecondary.monospacedDigit())
            .foregroundColor(.primaryForeground)
            .contentTransition(.numericText(value: Double(score)))
            .animation(.spring, value: score)
    }

    private func renderHealth() -> some View {
        HStack(spacing: 3) {
            ForEach(health, id: \.self) { _ in
                Rectangle()
                    .fill({
                        if health.count < 10 {
                            return Color.yellow
                        } else if health.count < 5 {
                            return Color.red
                        } else {
                            return Color.primaryForeground
                        }
                    }())
                    .frame(width: 2, height: 20)
            }
        }
        .animation(.spring, value: health)
    }

    @ViewBuilder
    private func renderPlayPause() -> some View {
        if case .play(let level) = state {
            Button {
                state = .pause(level: level)
            } label: {
                Image(systemName: "pause.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
                    .foregroundColor(.primaryForeground)
            }
            .buttonStyle(.bordered)
        } else if case .pause(let level) = state {
            Button {
                state = .play(level: level)
            } label: {
                Image(systemName: "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
                    .foregroundColor(.primaryForeground)
            }
            .buttonStyle(.automatic)
        }
    }
}

extension View {
    func renderHeadsUpDisplay(_ state: Binding<GameState>,
                              score: Int,
                              health: [Int]) -> some View {
        modifier(HeadsUpDisplay(state: state, score: score, health: health))
    }
}
