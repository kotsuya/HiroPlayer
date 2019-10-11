//
//  ProfileViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/21.
//  Copyright © 2018年 nakazato. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var nickNameField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.border(width: 1, color: .lightGray)            
        }
    }
    @IBOutlet weak var unsubsribeButton: UIButton! {
        didSet {
            unsubsribeButton.border(width: 1, color: .red)
        }
    }
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var profileButton: UIButton! {
        didSet {
            profileButton.border(width: 1, color: .black)
        }
    }
    
    @IBOutlet weak var emailButton: UIButton! {
        didSet {
            emailButton.border(width: 1, color: .black)
        }
    }
    
    @IBOutlet weak var passwordButton: UIButton! {
        didSet {
            passwordButton.border(width: 1, color: .black)
        }
    }
    
    private var user: User!
    private var profileImageChanged = false
    private var photoWebUrl: String!
    private var userDBRef: DatabaseReference!
    private var storageRef: StorageReference!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Profile"

        user = Auth.auth().currentUser
        userDBRef = Database.database().reference().child("users/\(user.uid)")
        storageRef = Storage.storage().reference()
        photoWebUrl = ""
        
        updateView()
    }
    
    private func updateView() {
        if let user = user {
            if let photoURL = user.photoURL {
                print("photoURL:\(photoURL)")
                let imageRef = storageRef.child("users/\(user.uid).png")
                spinner.startAnimating()
                imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        if let image = UIImage(data: data!) {
                            self.profileImageView.image = image
                        }
                    }
                    self.spinner.stopAnimating()
                }
            }
            
            if let nickName = user.displayName {
                nickNameField.text = nickName
            }
            
            if let email = user.email {
                emailField.text = email
            }
        }
    }
    
    private func credential(completion:@escaping (Bool) -> Void) {
        //アカウントの削除、メインのメールアドレスの設定、パスワードの変更といったセキュリティ上重要な操作を行うには、ユーザーが最近ログインしている必要があります。ユーザーが最近ログインしていない場合、このような操作を行うと失敗し、FIRAuthErrorCodeCredentialTooOld エラーになります。
        let alert = UIAlertController(title: "Please Input Password",
                                      message: user.email,
                                      preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: {
            (action: UIAlertAction!) in
            
            let textFields:Array<UITextField>? =  alert.textFields as Array<UITextField>?
            if textFields != nil {
                for textField:UITextField in textFields! {
                    /*
                     Email:
                     let credential = EmailAuthProvider.credential(withEmail: "some@email.com", password: "somepassword")
                     Facebook:
                     let credential = FacebookAuthProvider.credential(withAccessToken: "xxx")
                     Twitter:
                     let credential = FIRTwitterAuthProvider.credentialWithToken(session.authToken, secret: session.authTokenSecret)
                     Google:
                     let credential = GoogleAuthProvider.credential(withIDToken: "xxx", accessToken: "xxx")
                     */
                    if let email = self.user.email, let password = textField.text {
                        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                        self.user.reauthenticate(with: credential, completion: { (authDataResult, error) in
                            if let error = error {
                                print("error:\(error)")
                                completion(false)
                            } else {
                                completion(true)
                            }
                        })
                    }
                }
            }
        })
        alert.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        alert.addTextField(configurationHandler: {(text:UITextField!) -> Void in
            text.isSecureTextEntry = true
            text.placeholder = "Password"
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func imagePickerAction(_ sender: UITapGestureRecognizer) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }
    
    @IBAction func updateAction(_ sender: UIButton) {
        if let nickName = nickNameField.text, let photoWebUrl = photoWebUrl {
            let diplayName = user.displayName
            if diplayName == nil || diplayName != nickName || profileImageChanged {
                showSpinner {
                    let changeRequest = self.user.createProfileChangeRequest()
                    changeRequest.displayName = nickName
                    if self.profileImageChanged {
                        changeRequest.photoURL = URL(string: "users/\(self.user.uid).png")
                    }
                    changeRequest.commitChanges { (error) in
                        self.hideSpinner {
                            self.userDBRef.updateChildValues(["nickName":nickName,
                                                              "photoWebURL":photoWebUrl,
                                                              "updatedAt":Date().millisecondsSince1970])
                            self.showMessagePrompt("Profile Update Success!")
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func unsubsribeAction(_ sender: UIButton) {
        self.credential { (success) in
            if success {
                let alert = UIAlertController(title: "", message: "Really?", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { action in
                    self.user.delete { error in
                        if let error = error {
                            print("error:\(error)")
                        } else {
                            if let root = UIApplication.shared.rootVC {
                                self.dismiss(animated: true) {
                                    root.performSegue(withIdentifier: "toLoginView", sender: nil)
                                }
                            }
                        }
                    }
                })
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(cancel)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func emailUpdateAction(_ sender: UIButton) {
        self.credential { (success) in
            if success {
                let alert = UIAlertController(title: "Please Input New Email",
                                              message: nil,
                                              preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default, handler: {
                    (action: UIAlertAction!) in
                    let textFields:Array<UITextField>? =  alert.textFields as Array<UITextField>?
                    if textFields != nil {
                        for textField:UITextField in textFields! {
                            if let email = textField.text {
                                self.user.updateEmail(to: email) { (error) in
                                    self.userDBRef.updateChildValues(["email":email])
                                    self.showMessagePrompt("Email Update Success!")
                                }
                            }
                        }
                    }
                })
                alert.addAction(okAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(cancelAction)
                
                alert.addTextField(configurationHandler: {(text:UITextField!) -> Void in
                    text.placeholder = "Input New Email"
                })
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func passwordUpdateAction(_ sender: UIButton) {
        self.credential { (success) in
            if success {
                let alert = UIAlertController(title: "Please Input New Password",
                                              message: self.user.email,
                                              preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default, handler: {
                    (action: UIAlertAction!) in
                    let textFields:Array<UITextField>? =  alert.textFields as Array<UITextField>?
                    if textFields != nil {
                        for textField:UITextField in textFields! {
                            if let pw = textField.text {
                                self.user.updatePassword(to: pw) { (error) in
                                    self.showMessagePrompt("Password Update Success!")
                                }
                            }
                        }
                    }
                })
                alert.addAction(okAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(cancelAction)
                
                alert.addTextField(configurationHandler: {(text:UITextField!) -> Void in
                    text.isSecureTextEntry = true
                    text.placeholder = "Input New Password"
                })
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // キャンセルボタンを押された時に呼ばれる
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let newSize = CGSize(width: 100, height: 100)
            if image.size.width > 100 || image.size.height > 100 {
                profileImageView.image = image.resize(newSize)
            } else {
                profileImageView.image = image
            }
            
            if let img = profileImageView.image, let data = img.pngData() {                
                let imageRef = storageRef.child("users/\(user.uid).png")
                _ = imageRef.putData(data, metadata: nil) { (metadata, error) in
                    self.profileImageChanged = true
                    //guard let metadata = metadata else { return }
                    //let size = metadata.size
                    imageRef.downloadURL { (url, error) in
                        guard let downloadURL = url else { return }
                        //print("downloadURL:\(downloadURL):[\(size)]")
                        self.photoWebUrl = downloadURL.description
                    }
                }
            }
            
            dismiss(animated: true, completion: nil)
        }
    }
}
