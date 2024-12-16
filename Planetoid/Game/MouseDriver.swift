//
//  MouseDriver.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import Foundation

struct MouseDriver: PlutoDriver {
    private let initialState: CGFloat

    init?(initialState: CGFloat) {
        return nil
        self.initialState = initialState
    }

    func readAdjustmentValue() -> CGFloat {
        0
    }
}
