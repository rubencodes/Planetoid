//
//  InstructionsView.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct InstructionsView: View {

    // MARK: - Private Properties

    @Environment(\.playGame) private var playGame

    // MARK: - Body

    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 0) {
                Text("Are you ready?")
                    .font(.appTitleSecondary)

                Text("Pluto the Planetoid needs your help to become a planet again! Help Pluto navigate between the asteroids so he can show the other planets his skill. Tilt your phone back and forth to move up and down between the asteroids. Catch stars for good luck and extra points.")
                    .font(.appBody)
            }

            Button {
                playGame()
            } label: {
                Text("Play")
            }
            .buttonStyle(.primary)
        }
        .baseScreen()
    }
}

#Preview {
    InstructionsView()
}
