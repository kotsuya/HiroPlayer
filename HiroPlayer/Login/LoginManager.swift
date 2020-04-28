//
//  LoginManager.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/12/21.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import UIKit
import Firebase

class LoginManager {
    
    static let shared = LoginManager()
    
    public func setLastLogin(_ value: Date) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(value, forKey: "lastLogin")
        userDefaults.synchronize()
        
        if let uid = Auth.auth().currentUser?.uid {
            let ref  = Database.database().reference().child("users/\(uid)")
            ref.updateChildValues(["lastLogin":value.millisecondsSince1970])
        }
    }
    
    public func getLastLogin() -> Date? {
        let userDefaults = UserDefaults.standard
        guard let value: Date = userDefaults.object(forKey: "lastLogin") as? Date else {
            return nil
        }
        return value
    }
    
    public func setDaysInRow(_ value: Int) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(value, forKey: "daysInARow")
        userDefaults.synchronize()
        
        if let uid = Auth.auth().currentUser?.uid {
            let ref  = Database.database().reference().child("users/\(uid)")
            ref.updateChildValues(["daysInARow":"\(value)"])
        }
    }
    
    public func getDaysInRow() -> Int {
        let userDefaults = UserDefaults.standard
        guard let value: Int = userDefaults.object(forKey: "daysInARow") as? Int else {
            return 0
        }
        return value
    }
    
    public func checkLogin(result:@escaping ( String? ) -> Void) {
        //let creationDate = Auth.auth().currentUser?.metadata.creationDate
        //let lastSignInDate = Auth.auth().currentUser?.metadata.lastSignInDate

        //Checking strict days in a row
        if let lastLogin = self.getLastLogin() {
            if Calendar.current.isDateInToday(lastLogin) {
                setLastLogin(Date())
                result(nil)
            } else {
                var daysInARow = self.getDaysInRow()
                if Calendar.current.isDateInYesterday(lastLogin) {
                    daysInARow += 1
                } else {
                    daysInARow = 1
                }
                result(self.checkDaysInRow(daysInARow, lastLogin))
            }
        } else {
            result(self.checkDaysInRow(1, Date()))
        }
    }
    
    private func checkDaysInRow(_ daysInARow: Int, _ lastLogin: Date) -> String {
        setLastLogin(Date())
        setDaysInRow(daysInARow)
        
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let message = "now:\(f.string(from: Date()))\nlastLogin:\(f.string(from: lastLogin))\ndaysInARow:\(daysInARow)"
        return message
    }
    
    public func logout(success:@escaping() -> Void) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            let userDefaults = UserDefaults.standard
            if let domain = Bundle.main.bundleIdentifier {
                userDefaults.removePersistentDomain(forName: domain)
            }
            success()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}
