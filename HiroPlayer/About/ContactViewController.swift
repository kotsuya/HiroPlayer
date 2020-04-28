//
//  ContactViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/24.
//  Copyright © 2018 Yoo. All rights reserved.
//

import UIKit
import Firebase

class ContactViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.border(width: 1, color: .lightGray)
        }
    }
    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            sendButton.border(width: 1, color: .black)
        }
    }
    
    private var ref: DatabaseReference!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Contact us"
        
        ref = Database.database().reference()
    }
    
    @IBAction func sendAction(_ sender: UIButton) {
        guard let email = emailField.text else { return }
        guard let text = textView.text else { return }
        
        let alert = UIAlertController(title: "Contact Us", message: "Sent email. Please wait for a reply.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { aciton in
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(ok)
        present(alert, animated: true, completion: {
            let reference  = self.ref.child("contactus").childByAutoId()
            reference.setValue(["uid":reference.key?.description ?? "",
                                "email": email,
                                "text":text,
                                "createdAt":Date().description,
                                "treated":false])
        })
    }
    
}
