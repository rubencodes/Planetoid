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

    // MARK: - Nested Types

    enum LevelSuccess: String, CaseIterable {
        case stellar = "Stellar!"
        case rockStar = "Rock-star!"
        case outOfThisWorld = "Out of this world!"
    }

    enum LevelFailure: String, CaseIterable {
        case bummer = "Bummer!"
        case ohNo = "Oh no!"
        case oof = "Oof!"
        case ouch = "Ouch!"
        case yikes = "Yikes!"
    }

    // MARK: - Private Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var scene: GameScene
    @Binding private var state: GameState
    @State private var score: Int = Constants.kInitialScoreValue
    @State private var health: [Int] = {
        (0..<Constants.kInitialHealthValue).map { $0 }
    }()
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
        scene.isPaused = true
        _scene = .init(wrappedValue: scene)
    }

    // MARK: - Body

    var body: some View {
        SpriteView(scene: scene)
            .renderHeadsUpDisplay($state, score: score, health: health)
            .frame(width: size.width, height: size.height)
            .statusBarHidden()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .sensoryFeedback(.increase, trigger: Constants.kInitialHealthValue - health.count)
            .onChange(of: state) {
                switch state {
                case .presentNextLevel:
                    scene.isPaused = true
                case .play:
                    scene.isPaused = false
                case .pause:
                    scene.isPaused = true
                case .lost:
                    scene.isPaused = true
                }
            }
            .onChange(of: size, initial: true) {
                scene.size = size
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                guard case .play = state else { return }
                score += 1
            }
            .alert(LevelSuccess.allCases.randomElement()!.rawValue,
                   isPresented: .init(get: {
                guard case .presentNextLevel = state else {
                    return false
                }

                return true
            }, set: { _ in })) {
                Button(action: nextLevel) {
                    Text("Continue")
                }
            } message: {
                Text("Pluto survived this round with \(currentScore) points!")
            }
            .alert(LevelFailure.allCases.randomElement()!.rawValue,
                   isPresented: .init(get: {
                guard case .lost = state else {
                    return false
                }

                return true
            }, set: { _ in })) {
                Button(action: reset) {
                    Text("Try again")
                }
            } message: {
                Text("You couldn't make it past this wave of asteroids. Better luck next time! Score: \(currentScore), Level: \(state.level)")
            }
            .onAppear {
                scene.levelDelegate = self
            }
    }

    // MARK: - Private Functions

    private func reset() {
        dismiss()
    }

    private func nextLevel() {
        guard case .presentNextLevel(let level) = state else { return }
        state = .play(level: level)
    }
}

extension GameView: LevelDelegate {
    var availableSize: CGSize { size }
    var currentLevel: Int { state.level }
    var currentScore: Int { score }
    var currentHealth: Int { health.count }

    func play() {
        scene.isPaused = false
        state = .play(level: state.level)
    }

    // User lost life points
    @discardableResult
    func lifeLost(_ amount: Int = 1) -> Int {
        (0..<min(amount, health.count)).forEach { _ in
            _ = health.popLast()
        }

        //if the user is out of points, it's game over.
        if health.count == 0 {
            levelFailed()
        }

        return health.count
    }

    // User gained life points
    @discardableResult
    func lifeGained(_ amount: Int = 1) -> Int {
        (0..<amount).forEach { value in
            health.append(health.count + value)
        }

        return health.count
    }

    // User gained points
    @discardableResult
    func pointsGained(_ amount: Int = 1) -> Int {
        score += amount
        return score
    }

    func levelFailed() {
        state = .lost
    }

    func levelSucceeded() {
        state = .presentNextLevel(level: state.level + 1)
    }
}
