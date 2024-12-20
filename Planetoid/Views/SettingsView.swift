//
//  SettingsView.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/18/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Internal Properties

    @MainActor let dismiss: () -> Void

    // MARK: - Private Properties

    @AppStorage(GameSettingKey.isMusicEnabled.rawValue) private var isMusicEnabled: Bool = true
    @AppStorage(GameSettingKey.areSoundEffectsEnabled.rawValue) private var areSoundEffectsEnabled: Bool = true

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $isMusicEnabled) {
                    Text("Music")
                }
                .listRowBackground(Color.primaryBackground)

                Toggle(isOn: $areSoundEffectsEnabled) {
                    Text("Sound Effects")
                }
                .listRowBackground(Color.primaryBackground)
            } header: {
                renderHeader()
                    .padding(.top)
            } footer: {
                VStack {
                    Text("Copyright © 2024")
                    Text("Ruben Martinez Jr.")
                        .fontWeight(.semibold)
                }
                .font(.appCaption)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
        }
        .frame(maxWidth: 300, maxHeight: 320)
        .scrollContentBackground(.hidden)
        .foregroundStyle(.primaryForeground)
        .background(Color.primaryBackground.secondary)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8)
        .padding(20)
    }

    // MARK: - Private Properties

    private func renderHeader() -> some View {
        HStack {
            Text("Settings")
                .font(.appTitleSecondary)

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Label("Resume", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .padding(8)
                    .background(Circle().fill(.tertiary))
            }
        }
    }
}

#Preview("Landscape", traits: .landscapeLeft) {
    SettingsView {}
}

#Preview("Portrait", traits: .portrait) {
    SettingsView {}
}
