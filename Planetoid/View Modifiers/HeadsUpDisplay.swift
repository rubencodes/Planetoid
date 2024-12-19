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

    @State private var overlayMessage: String?

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay(HUDView(state: $state, score: score, health: health))
            .overlay(TitleOverlayView(title: $overlayMessage))
            .overlay(SettingsView(state: $state))
            .onChange(of: state.level, initial: true) {
                withAnimation(.spring) {
                    overlayMessage = "LEVEL \(state.level)"
                } completion: {
                    withAnimation(.spring.delay(0.5)) {
                        overlayMessage = nil
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
}

extension View {
    func renderHeadsUpDisplay(_ state: Binding<GameState>,
                              score: Int,
                              health: [Int]) -> some View {
        modifier(HeadsUpDisplay(state: state, score: score, health: health))
    }
}
