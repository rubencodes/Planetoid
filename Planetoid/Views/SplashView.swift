//
//  SplashView.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: -8) {
                Text("Planet   id")
                    .font(.appTitle)
                    .overlay {
                        Image(.pluto)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48)
                            .offset(x: 61, y: 2)
                    }

                Text("Help Pluto become a planet again!")
                    .font(.appSubtitle)
                    .fontWeight(.medium)
            }

            NavigationLink(value: Route.instructions) {
                Text("Continue")
                    .kerning(1)
                    .textCase(.uppercase)
                    .font(.appButton)
                    .fontWeight(.black)
            }
            .buttonStyle(.borderedProminent)
        }
        .baseScreen()
    }
}

#Preview {
    SplashView()
}
