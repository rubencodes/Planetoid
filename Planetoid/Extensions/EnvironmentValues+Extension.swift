//
//  EnvironmentValues+Extension.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct PlayGameKey: EnvironmentKey {
    static let defaultValue: @MainActor () -> Void = {}
}

extension EnvironmentValues {
    var playGame: @MainActor () -> Void {
        get { self[PlayGameKey.self] }
        set { self[PlayGameKey.self] = newValue }
    }
}

struct OpenSettingsKey: EnvironmentKey {
    static let defaultValue: @MainActor () -> Void = {}
}

extension EnvironmentValues {
    var openSettings: @MainActor () -> Void {
        get { self[OpenSettingsKey.self] }
        set { self[OpenSettingsKey.self] = newValue }
    }
}
