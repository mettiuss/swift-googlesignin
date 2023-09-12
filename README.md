# Google Sign In with Firebase in SwiftUI app

While working on my latest iOS app, I had quite a few difficulties finding an up-to-date guide on how to correctly set up Firebase Authentication in Swift 5.
I decided to write my first blog post in an attempt to fill this gap.

In this guide, I will show you how to build a simple app that lets users sign in using Google OAuth2.

![[signin-animation.gif]](https://miro.medium.com/v2/resize:fit:1400/1*CwsphXmDv0pLLRYwZrA6CQ.gif)
### Setting up Firebase
From the [Firebase console](https://console.firebase.google.com/u/0/) create a new project, then head to “Authentication” and click on `Get started`.

Then navigate to Sign-in method and enable the Google authentication flow.

![[authentication-google.jpg]](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*TqxMMQFd0fmyGLCMOpqhDg.jpeg)

### Setting up the SwiftUI app
Add the app to the Firebase project by clicking the button with the iOS logo and compiling the form.

![[firebase-app.jpg]](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*tIXOjHejPKHFctAuwF3eUA.jpeg)

When prompted, download the `GoogleService-Info.plist` and add it to the root of your Xcode project.

---

Let’s now install the necessary dependencies, in Xcode navigate to **File > Add Package Dependencies…**
In the search bar type `https://github.com/firebase/firebase-ios-sdk` and add the “FirebaseAuth” package product to your app.

![[xcode-firebase.png]](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*ETnOAQyTA3HG3-AKiqKH4w.png)

Now search for the Google Sign in package by typing `https://github.com/google/GoogleSignIn-iOS` and add the “GoogleSignIn” package product to your app.

---

Then open the project settings, navigate to "Info" and add a new entry under “URL Types” using the **+** button.
In “URL Schemas” write your REVERSED_CLIENT_ID, which you can find in your`GoogleService-Info.plist` file.

![[xcode-redirecturl.png]](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*ITkCxZKDPb6r8Dy8WDXQHQ.png)

---

We have now finished setting up the project, let's move on to the coding part...

In the `ExampleApp.swift` file we need to initialize Firebase and we have to handle the URL that your application will receive at the end of the Google authentication process.

```swift
import SwiftUI  
import Firebase  
import GoogleSignIn  
  
@main  
struct ExampleApp: App {  
    init() {  
        // Firebase initialization  
        FirebaseApp.configure()  
    }  
  
    var body: some Scene {  
        WindowGroup {  
            ContentView().onOpenURL { url in  
                //Handle Google Oauth URL  
                GIDSignIn.sharedInstance.handle(url)  
            }  
        }  
    }  
}
```

In the `ContentView.swift` file we need to check if the user is already logged in, and we will to listen for changes in the login status.

```swift
import SwiftUI  
import Firebase  
  
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
            //Firebase state change listeneer  
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
```

---

Let’s now build an Authentication class in `Authentication.swift`

```swift
import Foundation  
import Firebase  
import GoogleSignIn  
  
struct Authentication {  
    func googleOauth() async throws {  
        // google sign in  
        guard let clientID = FirebaseApp.app()?.options.clientID else {  
            fatalError("no firbase clientID found")  
        }  
  
        // Create Google Sign In configuration object.  
        let config = GIDConfiguration(clientID: clientID)  
        GIDSignIn.sharedInstance.configuration = config  
          
        //get rootView  
        let scene = await UIApplication.shared.connectedScenes.first as? UIWindowScene  
        guard let rootViewController = await scene?.windows.first?.rootViewController  
        else {  
            fatalError("There is no root view controller!")  
        }  
          
        //google sign in authentication response  
        let result = try await GIDSignIn.sharedInstance.signIn(  
            withPresenting: rootViewController  
        )  
        let user = result.user  
        guard let idToken = user.idToken?.tokenString else {  
            throw "Unexpected error occurred, please retry"  
        }  
          
        //Firebase auth  
        let credential = GoogleAuthProvider.credential(  
            withIDToken: idToken, accessToken: user.accessToken.tokenString  
        )  
        try await Auth.auth().signIn(with: credential)  
    }  
      
    func logout() async throws {  
        GIDSignIn.sharedInstance.signOut()  
        try Auth.auth().signOut()  
    }  
}  
  
  
extension String: Error {}
```

---

Finally we’ll build a simple Login screen in `Login.swift`
```swift
import SwiftUI  
  
struct Login: View {  
    @State private var err : String = ""  
      
    var body: some View {  
        Text("Login")  
        Button{  
            Task {  
                do {  
                    try await Authentication().googleOauth()  
                } catch let e {  
                    print(e)  
                    err = e.localizedDescription  
                }  
            }  
        }label: {  
            HStack {  
                Image(systemName: "person.badge.key.fill")  
                Text("Sign in with Google")  
            }.padding(8)  
        }.buttonStyle(.borderedProminent)  
          
        Text(err).foregroundColor(.red).font(.caption)  
    }  
}
```

As well as a basic home page in `Home.swift`

```swift
import SwiftUI  
import Firebase  
  
struct Home: View {  
    @State private var err : String = ""  
      
    var body: some View {  
        HStack {  
            Image(systemName: "hand.wave.fill")  
            Text(  
                "Hello " +  
                (Auth.auth().currentUser!.displayName ?? "Username not found")  
            )  
        }  
        Button{  
            Task {  
                do {  
                    try await Authentication().logout()  
                } catch let e {  
                    err = e.localizedDescription  
                }  
            }  
        }label: {  
            Text("Log Out").padding(8)  
        }.buttonStyle(.borderedProminent)  
          
        Text(err).foregroundColor(.red).font(.caption)  
    }  
}
```
