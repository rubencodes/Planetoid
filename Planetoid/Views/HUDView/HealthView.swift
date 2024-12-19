//
//  HealthView.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/18/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct HealthView: View {

    // MARK: - Internal Properties

    let health: [Int]

    // MARK: - Body

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(health.enumerated()), id: \.offset) { _ in
                Rectangle()
                    .fill({
                        if health.count < 10 {
                            return Color.yellow
                        } else if health.count < 5 {
                            return Color.red
                        } else {
                            return Color.primaryForeground
                        }
                    }())
                    .frame(width: 2, height: 20)
            }
        }
        .animation(.spring, value: health)
    }
}

#Preview("Default") {
    HealthView(health: Array(1...12))
}

#Preview("Warning") {
    HealthView(health: Array(1...8))
}

#Preview("Danger") {
    HealthView(health: Array(1...4))
}
