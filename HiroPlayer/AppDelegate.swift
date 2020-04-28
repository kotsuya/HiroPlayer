//
//  AppDelegate.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/14.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import Firebase
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    var player: AudioPlayer!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let audioSession = AVAudioSession.sharedInstance()
        let commandCenter = MPRemoteCommandCenter.shared()
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        let notificationCenter = NotificationCenter.default        
        self.player = AudioPlayer(dependencies: (audioSession, commandCenter, nowPlayingInfoCenter, notificationCenter))
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
                
        return true
    }

    // START Recive Message
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
        
        if let messageId = userInfo["gcm.message_id"] {
            print("Message ID : \(messageId)")
        }
        
        completionHandler(.newData)
    }
    
    // START message_handling
    // Receive displayed notifications for iOS 10 devices.
    // Handle incoming notification messages while app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        /*<UNNotification: 0x1c4038820; date: 2018-08-28 09:01:49 +0000, request: <UNNotificationRequest: 0x1c403d000; identifier: 263ECEFE-DC36-4419-8DD9-CB378A9C0D4E, content: <UNNotificationContent: 0x1c411fbf0; title: M, subtitle: (null), body: This is a Firebase Cloud Messaging Device Group Message!, categoryIdentifier: , launchImageName: , peopleIdentifiers: (
         ), threadIdentifier: , attachments: (
         ), badge: 1, sound: (null), hasDefaultAction: YES, defaultActionTitle: (null), shouldAddToNotificationsList: YES, shouldAlwaysAlertWhileAppIsForeground: NO, shouldLockDevice: NO, shouldPauseMedia: NO, isSnoozeable: NO, fromSnooze: NO, darwinNotificationName: (null), darwinSnoozedNotificationName: (null), trigger: <UNPushNotificationTrigger: 0x1c401a190; contentAvailable: NO, mutableContent: NO>>>
         */
        
        /*
         lldb) po userInfo
         ▿ 3 elements
         ▿ 0 : 2 elements
         ▿ key : AnyHashable("gcm.message_id")
         - value : "gcm.message_id"
         - value : 0:1535528920045807%cdba4e49cdba4e49
         ▿ 1 : 2 elements
         ▿ key : AnyHashable("aps")
         - value : "aps"
         ▿ value : 2 elements
         ▿ 0 : 2 elements
         - key : badge
         - value : 1
         ▿ 1 : 2 elements
         - key : alert
         ▿ value : 2 elements
         ▿ 0 : 2 elements
         - key : title
         - value : M
         ▿ 1 : 2 elements
         - key : body
         - value : This is a Firebase Cloud Messaging Device Group Message!
         ▿ 2 : 2 elements
         ▿ key : AnyHashable("google.c.a.e")
         - value : "google.c.a.e"
         - value : 1
         */
        if let messageId = userInfo["gcm.message_id"] {
            print("Message ID : \(messageId)")
        }
        
        completionHandler(.badge)
    }
    
    // Handle notification messages after display notification is tapped by the user.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let userInfo = response.notification.request.content.userInfo
        
        if let messageId = userInfo["gcm.message_id"] {
            print("Message ID : \(messageId)")
        }
        
        completionHandler()
    }
    
    // START refresh token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("FCM registration token: \(fcmToken)")
        
        // Notify about received token.
        let dataDic = ["token":fcmToken]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FCMToken"), object: nil, userInfo: dataDic)
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error)")
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let webURL = userActivity.webpageURL {
                print(webURL)
                self.handlePasswordlessSignInWithLink(webURL)
            }
        }
        
        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
            print("dynamiclink : \(String(describing: dynamiclink))")
        }
        
        return handled
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return application(app, open: url,
                           sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                           annotation: "")
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            print("dynamicLink : \(dynamicLink)")
            // Handle the deep link. For example, show the deep-linked content or
            // apply a promotional offer to the user's account.
            // ...
            return true
        }
        return false
    }
    
    func handlePasswordlessSignInWithLink(_ url:URL) {
        let link = url.absoluteString
        if Auth.auth().isSignIn(withEmailLink: link) {
            UserDefaults.standard.setValue(link, forKey: "Link")
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        //BadgeUtil.shared.setNumTagSecurity(0)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension UIApplication {
    var visibleVC: UIViewController? {
        return getVisibleViewController(nil)
    }
    
    var rootVC: UIViewController? {
        return getRootViewController(nil)
    }
    
    private func getRootViewController(_ rootViewController: UIViewController?) -> UIViewController? {
        if let rootVC = rootViewController ?? UIApplication.shared.keyWindow?.rootViewController {
            return rootVC
        }
        return nil
    }
    
    private func getVisibleViewController(_ rootViewController: UIViewController?) -> UIViewController? {
        if let rootVC = rootViewController ?? UIApplication.shared.keyWindow?.rootViewController {
            if rootVC.isKind(of: UINavigationController.self) {
                let navigationController = rootVC as! UINavigationController
                return getVisibleViewController(navigationController.viewControllers.last!)
            }
            
            if rootVC.isKind(of: UITabBarController.self) {
                let tabBarController = rootVC as! UITabBarController
                return getVisibleViewController(tabBarController.selectedViewController!)
            }
            
            if let presentedVC = rootVC.presentedViewController {
                return getVisibleViewController(presentedVC)
            }
            
            return rootVC
        }
        return nil
    }
}
