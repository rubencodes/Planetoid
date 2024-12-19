//
//  GameState.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import Foundation

enum GameState: Equatable {
    case orientationError(level: Int)
    case presentNextLevel(level: Int)
    case play(level: Int)
    case pause(level: Int)
    case loading
    case lost
}

extension GameState {
    var level: Int {
        switch self {
        case .orientationError(let level):
            return level
        case .presentNextLevel(let level):
            return level - 1
        case .play(let level):
            return level
        case .pause(let level):
            return level
        case .loading, .lost:
            return Constants.kInitialLevelValue
        }
    }

    var isPaused: Bool {
        guard case .play = self else { return true }
        return false
    }
}
