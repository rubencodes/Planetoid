//
//  ScoreView.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/18/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct ScoreView: View {

    // MARK: - Internal Properties

    let score: Int

    // MARK: - Body

    var body: some View {
        Text(String(format: "%05d", score))
            .font(.appTitleSecondary.monospacedDigit())
            .foregroundColor(.primaryForeground)
            .contentTransition(.numericText(value: Double(score)))
            .animation(.spring, value: score)
    }
}

#Preview {
    ScoreView(score: 50)
}
