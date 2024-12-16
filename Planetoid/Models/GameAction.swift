//
//  GameAction.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/16/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import Foundation

enum GameAction {
    case ready
    case levelSuccess
    case levelFailure
    case gainPoints(amount: Int = 1)
    case gainHealth(amount: Int = 1)
    case loseHealth(amount: Int = 1)
}
