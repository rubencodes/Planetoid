//
//  MouseDriver.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import Foundation

struct MouseDriver: PlutoDriver {

    // MARK: - Private Properties

    private let initialState: CGFloat

    // MARK: - Lifecycle

    init?(initialState: CGFloat) {
        self.initialState = initialState
    }

    // MARK: - Internal Functions

    func readAdjustmentValue() -> CGFloat {
        0
    }
}
