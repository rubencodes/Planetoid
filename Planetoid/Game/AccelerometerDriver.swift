//
//  AccelerometerDriver.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import CoreMotion
import Foundation

struct AccelerometerDriver: PlutoDriver {
    private let motionManager: CMMotionManager = .init()
    private let initialState: CGFloat

    init?(initialState: CGFloat) {
        self.init(initialState: initialState, updateInterval: 0.01)
    }

    init?(initialState: CGFloat, updateInterval: CGFloat) {
        guard motionManager.isAccelerometerAvailable else {
            return nil
        }

        self.initialState = initialState
        motionManager.startAccelerometerUpdates()
        motionManager.accelerometerUpdateInterval = updateInterval
    }

    func readAdjustmentValue() -> CGFloat {
        guard let data = motionManager.accelerometerData else {
            return 0
        }

        //move pluto according to its variation from the baseline
        return 20.0 * (CGFloat(initialState) - CGFloat(data.acceleration.z))
    }
}
