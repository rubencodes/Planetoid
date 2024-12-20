//
//  IconButtonStyle.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/19/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct IconButtonStyle: ButtonStyle {

    // MARK: - Private Properties

    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaledToFit()
            .labelStyle(.iconOnly)
            .frame(width: 24, height: 24)
            .padding(12)
            .foregroundStyle(.primaryForeground)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(x: configuration.isPressed ? 0.85 : 1,
                         y: configuration.isPressed ? 0.85 : 1)
            .animation(.interactiveSpring, value: isEnabled)
            .animation(.interactiveSpring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == IconButtonStyle {
    static var icon: IconButtonStyle {
        IconButtonStyle()
    }
}
