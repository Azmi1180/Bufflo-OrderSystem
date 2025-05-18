//
//  AppDelegate.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 16/05/25.
//
import UIKit
import FirebaseCore
import FirebaseAuth // If using Auth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    // Optional: Anonymous Sign-In for quick testing if you don't have full auth yet
    // Auth.auth().signInAnonymously { authResult, error in
    //   if let error = error {
    //     print("Error signing in anonymously: \(error.localizedDescription)")
    //   } else if let user = authResult?.user {
    //     print("Anonymous user signed in with UID: \(user.uid)")
    //   }
    // }
    return true
  }
}
