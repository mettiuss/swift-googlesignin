//
//  ExampleApp.swift
//  Example
//
//  Created by Matteo on 10/09/2023.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct ExampleApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView().onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
