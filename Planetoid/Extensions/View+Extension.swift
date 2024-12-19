//
//  View+Extension.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

extension View {
    func baseScreen() -> some View {
        padding()
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity)
            .font(.appBody)
            .foregroundColor(.primaryForeground)
            .background(StarfieldBackgroundView())
            .multilineTextAlignment(.center)
            .navigationBarBackButtonHidden()
    }

    func modifier(@ViewBuilder modifier: (_ view: Self) -> some View) -> some View {
        modifier(self)
    }
}
