//
//  View+Extension.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

extension View {
    func modifier(@ViewBuilder modifier: (_ view: Self) -> some View) -> some View {
        modifier(self)
    }
}
