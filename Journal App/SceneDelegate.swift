//
//  SceneDelegate.swift
//  Journal App
//
//  Created by Hui Ying on 22/04/2024.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var authController = Auth.auth()
    
    // If user logged in before, skip the login or register view controller and set the main
    // tab bar controller as the root view controller
    // https://fluffy.es/how-to-transition-from-login-screen-to-tab-bar-controller/
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // if user is logged in before
        if authController.currentUser != nil {
                // instantiate the main tab bar controller and set it as root view controller
                let mainTabBarController = storyboard.instantiateViewController(identifier: "MainTabBarController")
                window?.rootViewController = mainTabBarController
            } else {
                // if user isn't logged in
                // instantiate the log in or register view controller and set it as root view controller
                let loginNavController = storyboard.instantiateViewController(identifier: "LoginNavigationController")
                window?.rootViewController = loginNavController
            }
    }
    
    func changeRootViewController(_ vc: UIViewController, animated: Bool = true) {
        guard let window = self.window else {
            return
        }
        
        // change the root view controller to your specific view controller
        window.rootViewController = vc
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

