//
//  AboutViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/14.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import UIKit
import Firebase

class AboutViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("About", comment: "About")
    }
}

extension AboutViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? 2:1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        return section == 0 ? "Application Version: \(build)":nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.accessoryType = .disclosureIndicator
        if indexPath.section == 0 {
            cell.textLabel?.text = NSLocalizedString("Profile", comment: "Profile")
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("License", comment: "License")
            } else {
                cell.textLabel?.text = NSLocalizedString("Contact_us", comment: "Contact us")
            }
        } else if indexPath.section == 2 {
            cell.accessoryType = .none
            cell.textLabel?.text = "Sign out"
            cell.textLabel?.textColor = .red
            cell.textLabel?.textAlignment = .center
        }
        
        return cell
    }
}

extension AboutViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            performSegue(withIdentifier: "toProfileView", sender: nil)            
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                //License
                //performSegue(withIdentifier: "toWebView", sender: nil)
                showMessagePrompt(NSLocalizedString("Preparing", comment: "Preparing"))
            } else {
                //Contact us
                performSegue(withIdentifier: "toContactView", sender: nil)
            }
        } else if indexPath.section == 2 { //logout
            LoginManager.shared.logout() {
                if let root = UIApplication.shared.rootVC {
                    self.dismiss(animated: true) {
                        root.performSegue(withIdentifier: "toLoginView", sender: nil)
                    }
                }
            }
        }
    }
}
