//
//  SplashViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/17.
//  Copyright © 2018 Yoo. All rights reserved.
//

import UIKit
import Firebase

class SplashViewController: UIViewController {

    private var remoteConfig : RemoteConfig!
    var handle: AuthStateDidChangeListenerHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        
        remoteConfig.fetch(withExpirationDuration: TimeInterval(0)) { [ weak self]
            (status, error) -> Void in
            if status == .success {
                print("Config fetched")
                self?.remoteConfig.activate()
            } else {
                print("Config not fetched")
                print("ERROR : \(error!.localizedDescription)")
            }
            
            self?.displayWelcome()
        }        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Auth.auth().removeStateDidChangeListener(handle)
    }
  
    private func displayWelcome() {
        let caps = remoteConfig["splash_message_caps"].boolValue
        let message = remoteConfig["splash_message"].stringValue
        
        if caps {
            let alert = UIAlertController(title: "NOTICE", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                exit(0)
            }))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            handle = Auth.auth().addStateDidChangeListener { (auth, user) in
                if user != nil {
                    // login bonus用
                    LoginManager.shared.checkLogin(result: { (message) in
                        if let message = message {
                            self.showMessagePrompt("Login", message, buttonHandler: {_ in 
                                self.moveToTabbar()
                            })
                        } else {
                            self.moveToTabbar()
                        }
                    })
                } else {
                    self.performSegue(withIdentifier: "toLoginView", sender: nil)
                }
            }
        }
        
        if let color = remoteConfig["splash_background"].stringValue {
            self.view.backgroundColor = UIColor(hex: color)
        }
    }
    
    private func moveToTabbar() {
        performSegue(withIdentifier: "toTabbar", sender: nil)
    }
}
