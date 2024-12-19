//
//  StarfieldBackgroundView.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

struct StarfieldBackgroundView: View {

    // MARK: - Private Properties

    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible: Bool = false
    @State private var offset: CGFloat = .zero
    private var x: [CGFloat] = (0..<1000).map { _ in CGFloat.random(in: 0..<1) }
    private var y: [CGFloat] = (0..<1000).map { _ in CGFloat.random(in: 0..<1) }

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            Color.primaryBackground
                .overlay {
                    ForEach((0..<1000)) { value in
                        let availableSize: CGSize = proxy.size
                        let point = CGPoint(x: (availableSize.width * x[value]) * 5,
                                            y: (availableSize.height * y[value]) * 5)
                        Rectangle()
                            .fill(.primaryForeground.opacity(0.4))
                            .frame(width: offset, height: 1)
                            .position(x: point.x, y: point.y)
                            .offset(x: -offset)
                    }
                }
                .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                    guard isVisible, scenePhase == .background else { return }
                    withAnimation {
                        offset += 1
                    }
                }
                .onAppear {
                    isVisible = true
                }
                .onDisappear {
                    isVisible = false
                }
        }
        .ignoresSafeArea()
    }
}

#Preview(traits: .landscapeLeft) {
    StarfieldBackgroundView()
}
