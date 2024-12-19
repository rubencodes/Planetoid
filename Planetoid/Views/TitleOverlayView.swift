//
//  TitleOverlayView.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/18/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct TitleOverlayView: View {

    // MARK: - Internal Properties

    @Binding var title: String?

    // MARK: - Body

    var body: some View {
        if let title {
            Text(title)
                .font(.appTitle)
                .foregroundColor(.primaryForeground)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
        }
    }
}

#Preview {
    TitleOverlayView(title: .constant("LEVEL 1"))
}
