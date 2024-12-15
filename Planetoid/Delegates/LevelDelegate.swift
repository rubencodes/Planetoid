//
//  LevelDelegate.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import Foundation

protocol LevelDelegate {

    @MainActor var availableSize: CGSize { get }
    @MainActor var currentLevel: Int { get }
    @MainActor var currentScore: Int { get }
    @MainActor var currentHealth: Int { get }

    @MainActor func play()
    @discardableResult
    @MainActor func lifeLost(_ amount: Int) -> Int
    @discardableResult
    @MainActor func lifeGained(_ amount: Int) -> Int
    @discardableResult
    @MainActor func pointsGained(_ amount: Int) -> Int
    @MainActor func levelFailed()
    @MainActor func levelSucceeded()
}

struct MockLevelDelegate: LevelDelegate {
    var availableSize: CGSize = .zero
    
    var currentLevel: Int = 0

    var currentScore: Int = 0

    var currentHealth: Int = 0

    func play() {}
    
    func lifeLost(_ amount: Int) -> Int { 0 }

    func lifeGained(_ amount: Int) -> Int { 0 }

    func pointsGained(_ amount: Int) -> Int { 0 }

    func levelFailed() {}

    func levelSucceeded() {}
}
