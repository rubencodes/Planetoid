//
//  GameView.swift
//  Planetoid
//
//  Created by Ruben on 6/17/15.
//  Copyright (c) 2015 Ruben. All rights reserved.
//

import UIKit
import SwiftUI
import SpriteKit

struct GameView: View {

    // MARK: - Private Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var scene: GameScene
    @Binding private var state: GameState
    @State private var score: Int = Constants.kInitialScoreValue
    @State private var health: [Int] = {
        (0..<Constants.kInitialHealthValue).map { $0 }
    }()
    private let scoreTimer = Timer.publish(every: 1, on: .main, in: .common)
    private let size: CGSize

    // MARK: - Lifecycle

    init(state: Binding<GameState>,
         size: CGSize) {
        _state = state
        self.size = size

        let scene = GameScene()
        scene.size = size
        scene.scaleMode = .fill
        scene.backgroundColor = .primaryBackground
        _scene = .init(wrappedValue: scene)
    }

    // MARK: - Body

    var body: some View {
        SpriteView(scene: scene)
            .frame(width: size.width, height: size.height)
            .renderHeadsUpDisplay($state, score: score, health: health)
            .presentSuccessMessage($state)
            .presentFailureMessage($state)
            .lockOrientation(.landscape)
            .statusBarHidden()
            .sensoryFeedback(.increase, trigger: Constants.kInitialHealthValue - health.count)
            .onReceive(scoreTimer.autoconnect()) { _ in
                guard case .play = state else { return }
                score += 1
            }
            .onChange(of: state, initial: true) {
                scene.isPaused = state.isPaused
            }
            .onChange(of: size, initial: true) {
                scene.size = size
                scene.levelDelegate = self
            }
    }
}

extension GameView: GameDelegate {

    var currentLevel: Int { state.level }
    var currentScore: Int { score }
    var currentHealth: Int { health.count }

    func execute(_ action: GameAction) {
        switch action {
        case .ready:
            state = .play(level: state.level)
        case .gainPoints(let amount):
            score += amount
        case .gainHealth(let amount):
            (0..<amount).forEach { value in
                health.append(health.count + value)
            }
        case .loseHealth(let amount):
            (0..<min(amount, health.count)).forEach { _ in
                _ = health.popLast()
            }

            // if the user is out of points, it's game over.
            if health.count == 0 {
                state = .lost
            }
        case .levelSuccess:
            state = .presentNextLevel(level: state.level + 1)
        case .levelFailure:
            state = .lost
        }
    }
}
