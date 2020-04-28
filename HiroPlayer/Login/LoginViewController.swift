//
//  LoginViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/17.
//  Copyright © 2018 Yoo. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var createButton: UIButton! {
        didSet {
            createButton.border(width: 1, color: .black)
        }
    }
    @IBOutlet weak var signInButton: UIButton! {
        didSet {
            signInButton.border(width: 1, color: .black)
        }
    }
    @IBOutlet weak var passwordResetButton: UIButton! {
        didSet {
            passwordResetButton.border(width: 1, color: .black)
        }
    }
    @IBOutlet weak var showProviderButton: UIButton! {
        didSet {
            showProviderButton.border(width: 1, color: .black)
        }
    }
    var tutorial:Tutorial = Tutorial.shared
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        let notificationCenter = NotificationCenter.default
//        notificationCenter.addObserver(self, selector: #selector(viewWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(viewDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tutorial.status = .createId
        showTutorial()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        let notificationCenter = NotificationCenter.default
//        notificationCenter.removeObserver(self)
    }
    
//    @objc func viewWillEnterForeground(_ notification: NSNotification?) {
//        if (self.isViewLoaded && (self.view.window != nil)) {
//            print("フォアグラウンド")
//            loginAction()
//        }
//    }
    
//    @objc func viewDidEnterBackground(_ notification: NSNotification?) {
//        if (self.isViewLoaded && (self.view.window != nil)) {
//            print("バックグラウンド")
//        }
//    }
    
    @IBAction func signInAction(_ sender: UIButton) {
        if let email = self.emailField.text, let password = self.passwordField.text {
            showSpinner {
                // [START headless_email_auth]
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    // [START_EXCLUDE]
                    self.hideSpinner {
                        if let error = error {
                            self.showMessagePrompt(error.localizedDescription)
                            return
                        }
                        
                        LoginManager.shared.checkLogin(result: { (message) in
                            if let message = message {
                                self.showMessagePrompt("Login", message) { _ in
                                    self.moveToTabbar()
                                }
                            } else {
                                self.moveToTabbar()
                            }
                        })
                    }
                    // [END_EXCLUDE]
                }
                // [END headless_email_auth]
            }
        } else {
            self.showMessagePrompt("email/password can't be empty")
        }
    }
    
    private func moveToTabbar() {
        performSegue(withIdentifier: "toTabbar", sender: nil)
    }
    
    @IBAction func createAction(_ sender: UIButton) {
        guard let email = emailField.text, let password = passwordField.text else {
            self.showMessagePrompt("email/password can't be empty")
            return
        }
        self.showSpinner {
            // [START create_user]
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                // [START_EXCLUDE]
                self.hideSpinner {
                    guard let email = authResult?.user.email, error == nil else {
                        self.showMessagePrompt(error!.localizedDescription)
                        return
                    }
                    
                    print("\(email) created")
                    self.insertUserDb(authResult?.user)
                    self.showMessagePrompt("\(email) created\nPlease touch [sign in] button")
                }
                // [END_EXCLUDE]
                guard let user = authResult?.user else { return }
                print("user:\(user)")
            }
            // [END create_user]
        }
    }
    
    private func insertUserDb(_ user: User?) {
        guard let user = user, let email = user.email else {
            self.showMessagePrompt("Insert to DB ERROR - USERS")
            return
        }
        
        let ref  = Database.database().reference().child("users/\(user.uid)")
        ref.setValue(["uid":user.uid,
                      "email": email,
                      "nickName": "",
                      "photoWebURL": "",
                      "lastLogin": "",
                      "daysInARow": "",
                      "updatedAt": "",
                      "createdAt":Date().millisecondsSince1970])
    }
    
    @IBAction func passwordResetAction(_ sender: UIButton) {
        guard let email = emailField.text else {
            self.showMessagePrompt("email can't be empty")
            return
        }
        self.showSpinner {
            // [START password_reset]
            Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                // [START_EXCLUDE]
                self.hideSpinner {
                    if let error = error {
                        self.showMessagePrompt(error.localizedDescription)
                        return
                    }
                    self.showMessagePrompt("Sent")
                }
                // [END_EXCLUDE]
            }
            // [END password_reset]
        }
    }
    
    @IBAction func showProviderAction(_ sender: UIButton) {
        guard let email = emailField.text else {
            self.showMessagePrompt("email can't be empty")
            return
        }
        self.showSpinner {
            // [START get_providers]
            Auth.auth().fetchSignInMethods(forEmail: email) { (providers, error) in
                // [START_EXCLUDE]
                self.hideSpinner {
                    if let error = error {
                        self.showMessagePrompt(error.localizedDescription)
                        return
                    }
                    //self.showMessagePrompt(providers!.joined(separator: ", "))
                    if providers == nil {
                        self.showMessagePrompt("No password. No active account")
                    } else {
                        self.showMessagePrompt("There is an active account")
                    }
                }
                // [END_EXCLUDE]
            }
            // [END get_providers]
        }
    }   
}

extension LoginViewController: UIPopoverPresentationControllerDelegate {
    
    func showTutorial() {
        if tutorial.status == .none { return }
        if tutorial.status == .tutorialEnd {
            UIView.animate(withDuration: 0.4, animations: {() -> Void  in
                self.view.alpha = 1.0
            }, completion: { (finish) -> Void in
                self.tutorial.status = .none
            })
            return
        }
        
        self.view.alpha = 0.8
        let txtViewController = TutorialViewController()
        txtViewController.textStr = tutorial.status.message
        txtViewController.textViewBackgroundColor = .clear
        txtViewController.modalPresentationStyle = .popover
//        txtViewController.frameWidth = 200
//        txtViewController.frameHeight = txtViewController.frameWidth / 4
        txtViewController.preferredContentSize = CGSize(width: txtViewController.frameWidth, height: txtViewController.frameHeight)
        
        let popoverController = txtViewController.popoverPresentationController
        popoverController?.permittedArrowDirections = .any
        popoverController?.delegate = self

        if tutorial.status == .createId {
            popoverController?.sourceView = createButton
            popoverController?.sourceRect = createButton.bounds
            tutorial.status = .signIn
        } else if tutorial.status == .signIn {            
            popoverController?.sourceView = signInButton
            popoverController?.sourceRect = signInButton.bounds
            tutorial.status = .passwordReset
        } else if tutorial.status == .passwordReset {
            popoverController?.sourceView = passwordResetButton
            popoverController?.sourceRect = passwordResetButton.bounds
            tutorial.status = .provider
        } else if tutorial.status == .provider {
            popoverController?.sourceView = showProviderButton
            popoverController?.sourceRect = showProviderButton.bounds
            tutorial.status = .tutorialEnd
        }
        present(txtViewController, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        showTutorial()
    }
}
