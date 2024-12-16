//
//  GameState.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import Foundation

enum GameState: Equatable {
    case presentNextLevel(level: Int)
    case play(level: Int)
    case pause(level: Int)
    case lost
}

extension GameState {
    var level: Int {
        switch self {
        case .presentNextLevel(let level):
            return level - 1
        case .play(let level):
            return level
        case .pause(let level):
            return level
        case .lost:
            return Constants.kInitialLevelValue
        }
    }

    var isPaused: Bool {
        guard case .play = self else { return true }
        return false
    }
}
