//
//  ContentView.swift
//  Example
//
//  Created by Matteo on 10/09/2023.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var userLoggedIn = (Auth.auth().currentUser != nil)

    var body: some View {
        VStack {
            if userLoggedIn {
                Home()
            } else {
                Login()
            }
        }.onAppear{
            Auth.auth().addStateDidChangeListener{ auth, user in
                if (user != nil) {
                    userLoggedIn = true
                } else {
                    userLoggedIn = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
