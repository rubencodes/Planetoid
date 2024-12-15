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
                        GameView(size: proxy.size)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
