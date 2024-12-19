//
//  LevelDelegate.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import Foundation

protocol GameDelegate {
    @MainActor var currentLevel: Int { get }
    @MainActor var currentScore: Int { get }
    @MainActor var currentHealth: Int { get }
    @MainActor var isPaused: Bool { get }

    @MainActor func execute(_ action: GameAction)
}
