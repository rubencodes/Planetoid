//
//  PrimaryButtonStyle.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {

    // MARK: - Private Properties

    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .kerning(1)
            .textCase(.uppercase)
            .font(.appButton)
            .fontWeight(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.accent)
            .clipShape(Capsule())
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(x: configuration.isPressed ? 0.9 : 1,
                         y: configuration.isPressed ? 0.9 : 1)
            .animation(.spring, value: isEnabled)
            .animation(.spring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }
}
