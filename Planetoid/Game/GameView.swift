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

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var scene: GameScene
    @Binding private var state: GameState
    @State private var score: Int = Constants.kInitialScoreValue
    @State private var health: [Int] = Array(0..<Constants.kInitialHealthValue)
    private let scoreTimer = Timer.publish(every: 1, on: .main, in: .common)
    private let size: CGSize

    private var isCorrectOrientation: Bool {
        size.width > size.height
    }

    private var hasInitialized: Bool {
        state != .loading
    }

    // MARK: - Lifecycle

    init(state: Binding<GameState>,
         size: CGSize) {
        _state = state
        self.size = size

        let scene = GameScene()
        scene.size = size
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .primaryBackground
        _scene = .init(wrappedValue: scene)
    }

    // MARK: - Body

    var body: some View {
        SpriteView(scene: scene)
            .frame(width: size.width, height: size.height)
            .renderHeadsUpDisplay($state, score: score, health: health)
            .orientationLock($state, isCorrectOrientation: isCorrectOrientation)
            .presentSuccessMessage($state)
            .presentFailureMessage($state)
            .statusBarHidden()
            .font(.appBody)
            .onReceive(scoreTimer.autoconnect()) { _ in
                guard case .play = state else { return }
                score += 1
            }
            .onChange(of: scenePhase, initial: true) {
                guard scenePhase != .active else { return }
                state = .pause(level: state.level)
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

// MARK: - GameDelegate

extension GameView: GameDelegate {

    var currentLevel: Int { state.level }
    var currentScore: Int { score }
    var currentHealth: Int { health.count }
    var isPaused: Bool { state.isPaused }

    func execute(_ action: GameAction) {
        switch action {
        case .ready:
            guard isCorrectOrientation else {
                state = .orientationError(level: state.level)
                return
            }

            state = .play(level: state.level)
        case .gainPoints(let amount):
            score += amount
        case .gainHealth(let amount):
            health = Array(0..<health.count + amount)
        case .loseHealth(let amount):
            let newValue = max(health.count - amount, 0)
            health = if newValue > 0 {
                Array(0..<newValue)
            } else {
                Array()
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
