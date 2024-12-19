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

    @Binding var state: GameState

    // MARK: - Private Properties

    @AppStorage(GameSettingKey.isMusicEnabled.rawValue) private var isMusicEnabled: Bool = true
    @AppStorage(GameSettingKey.areSoundEffectsEnabled.rawValue) private var areSoundEffectsEnabled: Bool = true

    // MARK: - Body

    var body: some View {
        if case .pause = state {
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
            .frame(maxWidth: 300)
            .scrollContentBackground(.hidden)
            .foregroundStyle(.primaryForeground)
            .background(Color.primaryBackground.secondary)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 8)
            .padding(20)
        }
    }

    // MARK: - Private Properties

    private func renderHeader() -> some View {
        HStack {
            Text("Settings")
                .font(.appTitleSecondary)

            Spacer(minLength: 0)

            Button {
                state = .play(level: state.level)
            } label: {
                Label("Resume", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .padding(8)
                    .background(Circle().fill(.tertiary))
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    SettingsView(state: .constant(.pause(level: 1)))
}
