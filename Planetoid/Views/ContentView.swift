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

    @State private var gameState: GameState = .loading
    @State private var isPlayingGame: Bool = false
    @State private var isShowingSettings: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            SplashView()
                .environment(\.openSettings) {
                    isShowingSettings = true
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .instructions:
                        InstructionsView()
                            .environment(\.playGame) {
                                isPlayingGame = true
                            }
                            .environment(\.openSettings) {
                                isShowingSettings = true
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
                .blur(radius: isShowingSettings ? 10 : 0)
                .overlay {
                    if isShowingSettings {
                        SettingsView {
                            isShowingSettings = false
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
                    }
                }
                .animation(.spring, value: isShowingSettings)
                .background {
                    Color.primaryBackground.ignoresSafeArea()
                }
        }
        .background(Color.primaryBackground)
    }
}

#Preview {
    ContentView()
}
