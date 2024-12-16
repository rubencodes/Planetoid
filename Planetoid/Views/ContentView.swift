//
//  ContentView.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Private Properties

    @State private var gameState: GameState = .pause(level: Constants.kInitialLevelValue)
    @State private var isPlayingGame: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            SplashView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .instructions:
                        InstructionsView()
                            .environment(\.playGame) {
                                isPlayingGame = true
                            }
                    }
                }
                .fullScreenCover(isPresented: $isPlayingGame) {
                    GeometryReader { proxy in
                        GameView(state: $gameState,
                                 size: proxy.size)
                            .id(gameState.level)
                    }
                }
        }
        .background(.primaryBackground)
    }
}

#Preview {
    ContentView()
}
