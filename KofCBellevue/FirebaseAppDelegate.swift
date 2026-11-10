//
//  FirebaseAppDelegate.swift
//  KofCBellevue
//
//  Created by Shebin on 11/9/26.
//

import Foundation
import UIKit
import FirebaseCore

final class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        #if DEBUG
        print("Firebase initialized.")
        print(
            "Firebase project:",
            FirebaseApp.app()?.options.projectID ?? "Unknown"
        )
        #endif

        return true
    }
}
