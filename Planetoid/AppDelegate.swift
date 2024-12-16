//
//  AppDelegate.swift
//  Planetoid
//
//  Created by Ruben Martinez Jr. on 12/16/24.
//  Copyright © 2024 Ruben. All rights reserved.
//

import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Static Properties

    static var orientationLock = UIInterfaceOrientationMask.allButUpsideDown

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
