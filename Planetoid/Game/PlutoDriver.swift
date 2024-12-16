//
//  PlutoDriver.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import Foundation

protocol PlutoDriver {
    init?(initialState: CGFloat)

    func readAdjustmentValue() -> CGFloat
}
