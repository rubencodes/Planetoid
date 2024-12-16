//
//  LevelSuccessDisplay.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/16/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct LevelSuccessDisplay: ViewModifier {

    // MARK: - Nested Types

    enum LevelSuccess: String, CaseIterable {
        case stellar = "Stellar!"
        case rockStar = "Rock-star!"
        case outOfThisWorld = "Out of this world!"
    }

    // MARK: - Internal Properties

    @Binding var state: GameState

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .alert(LevelSuccess.allCases.randomElement()!.rawValue,
                   isPresented: .init(get: {
                guard case .presentNextLevel = state else {
                    return false
                }

                return true
            }, set: { _ in })) {
                Button {
                    state = .play(level: state.level + 1)
                } label: {
                    Text("Continue")
                }
            } message: {
                Text("Pluto survived this round! Let's keep moving forward.")
            }
    }
}

extension View {
    func presentSuccessMessage(_ state: Binding<GameState>) -> some View {
        modifier(LevelSuccessDisplay(state: state))
    }
}
