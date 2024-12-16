//
//  View+Extension.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/15/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import SwiftUI

extension View {
    func baseScreen() -> some View {
        padding()
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity)
            .foregroundColor(.primaryForeground)
            .background(StarfieldBackgroundView())
            .multilineTextAlignment(.center)
            .navigationBarBackButtonHidden()
    }

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) -> some View {
        task {
            // Forcing the rotation to portrait
            await MainActor.run {
                AppDelegate.orientationLock = orientation
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }.onDisappear {
            // Unlocking the rotation when leaving the view
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.allButUpsideDown
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
}
