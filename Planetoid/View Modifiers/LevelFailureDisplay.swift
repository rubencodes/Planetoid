//
//  LevelFailureDisplay.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/16/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct LevelFailureDisplay: ViewModifier {

    // MARK: - Nested Types

    enum LevelFailure: String, CaseIterable {
        case bummer = "Bummer!"
        case ohNo = "Oh no!"
        case oof = "Oof!"
        case ouch = "Ouch!"
        case yikes = "Yikes!"
    }

    // MARK: - Internal Properties

    @Binding var state: GameState

    // MARK: - Private Properties

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .alert(LevelFailure.allCases.randomElement()!.rawValue,
                   isPresented: .init(get: {
                guard case .lost = state else {
                    return false
                }

                return true
            }, set: { _ in })) {
                Button {
                    dismiss()
                } label: {
                    Text("Try again")
                }
            } message: {
                Text("You couldn't make it past this wave of asteroids. Better luck next time!")
            }
    }
}

extension View {
    func presentFailureMessage(_ state: Binding<GameState>) -> some View {
        modifier(LevelFailureDisplay(state: state))
    }
}
