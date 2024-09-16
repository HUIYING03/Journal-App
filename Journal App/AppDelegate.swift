//
//  AppDelegate.swift
//  Journal App
//
//  Created by Hui Ying on 22/04/2024.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var databaseController: DatabaseProtocol?
    var notificationsEnabled = false
    static let SLEEP_IDENTIFIER = "edu.monash.fit3178.sleepreminder"
    static let CATEGORY_IDENTIFIER = "edu.monash.fit3178.todoreminder"
    
    
    // Request authorization once the app finish launching
    // Modified from FIT3178 Workshop 10: Local Notification
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        databaseController = FirebaseController()
        
        Task {
            let notificationCenter = UNUserNotificationCenter.current()
            let notificationSettings = await notificationCenter.notificationSettings()
            if notificationSettings.authorizationStatus == .notDetermined {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert])
                self.notificationsEnabled = granted
            }
            else if notificationSettings.authorizationStatus == .authorized {
                self.notificationsEnabled = true
            }
        }
        
        let doneAction = UNNotificationAction(identifier: "done", title: "Done", options: .foreground)
        
        let appCategory = UNNotificationCategory(identifier: AppDelegate.CATEGORY_IDENTIFIER, actions: [doneAction], intentIdentifiers: [], options: UNNotificationCategoryOptions(rawValue: 0))
//        
        UNUserNotificationCenter.current().setNotificationCategories([appCategory])
        
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        print("Will present notification: \(notification.request.identifier)")
        return [.banner]
    }
    
    
    // If response received from the reminder sent for the to do task, mark the task as done
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("Did receive notification response: \(response.actionIdentifier)")
        if response.notification.request.content.categoryIdentifier == AppDelegate.CATEGORY_IDENTIFIER {
            switch response.actionIdentifier {
            case "done":
                guard let identifier = response.notification.request.content.userInfo["identifier"] as? String else {
                        print("Unable to retrieve notification identifier")
                        return
                    }
                databaseController?.markAsDone(notification: identifier)
                            
            default:
                print("other")
            }
        } else {
            print("sleep reminder")
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

