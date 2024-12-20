//
//  BaseScreen.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/19/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct BaseScreen: ViewModifier {

    // MARK: - Private Properties

    @Environment(\.openSettings) private var openSettings

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity)
            .font(.appBody)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    openSettings()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.icon)
                .padding(12)
            }
            .foregroundColor(.primaryForeground)
            .background(StarfieldBackgroundView())
            .multilineTextAlignment(.center)
            .navigationBarBackButtonHidden()
    }
}

extension View {
    func baseScreen() -> some View {
        modifier(BaseScreen())
    }
}
