//
//  OrientationLock.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/18/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct OrientationLock: ViewModifier {

    // MARK: - Nested Types

    struct OverlayView: View {
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .symbolEffect(.rotate)
                Text("Rotate Device to Start")
            }
            .font(.appSubtitle)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.primaryForeground)
            .background {
                Color.primaryBackground.ignoresSafeArea()
            }
        }
    }

    // MARK: - Internal Properties

    @Binding var state: GameState
    let isCorrectOrientation: Bool

    // MARK: - Body

    func body(content: Content) -> some View {
        ZStack {
            if isCorrectOrientation {
                content
            } else {
                OverlayView()
                    .transition(.opacity.combined(with: .symbolEffect))
            }
        }
        .animation(.easeInOut, value: state)
        .onChange(of: state, initial: true) {
            updateStateForOrientation()
        }
        .onChange(of: isCorrectOrientation, initial: true) {
            updateStateForOrientation()
        }
    }

    private func updateStateForOrientation() {
        switch state {
        case .orientationError, .play: break
        default: return
        }

        guard isCorrectOrientation else {
            state = .orientationError(level: state.level)
            return
        }

        state = .play(level: state.level)
    }
}

extension View {
    func orientationLock(_ state: Binding<GameState>,
                         isCorrectOrientation: Bool) -> some View {
        modifier(OrientationLock(state: state, isCorrectOrientation: isCorrectOrientation))
    }
}

#Preview {
    OrientationLock.OverlayView()
}
