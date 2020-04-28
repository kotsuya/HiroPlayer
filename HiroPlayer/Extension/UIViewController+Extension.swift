//
//  UIViewController+Extension.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/19.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import UIKit

extension UIViewController {
    func showSpinner(completion:@escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: "Please Wait...\n\n\n", preferredStyle: .alert)
        
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.color = .black
        spinner.center = CGPoint(x: alert.view.bounds.size.width / 2,
                                 y: alert.view.bounds.size.height / 2 + 64)
        spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin,
                                    .flexibleLeftMargin, .flexibleRightMargin]
        spinner.startAnimating()
        alert.view.addSubview(spinner)
        
        self.present(alert, animated: true, completion: completion)
    }
    
    func hideSpinner(completion:@escaping () -> Void) {
        self.dismiss(animated: true, completion: completion)
    }
    
    func showMessagePrompt(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showMessagePrompt(_ title: String, _ message: String, buttonHandler:@escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: buttonHandler))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showMessagePrompt(_ title: String, _ message: String, _ btnTitle:String ,buttonHandler:@escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: btnTitle, style: .default, handler: buttonHandler))
        self.present(alert, animated: true, completion: nil)
    }
    
    func setTabBarHidden(_ hidden: Bool, animated: Bool = true, duration: TimeInterval = 0.5) {
        if self.tabBarController?.tabBar.isHidden != hidden{
            if animated {
                //Show the tabbar before the animation in case it has to appear
                if (self.tabBarController?.tabBar.isHidden)!{
                    self.tabBarController?.tabBar.isHidden = hidden
                }
                if let frame = self.tabBarController?.tabBar.frame {
                    let factor: CGFloat = hidden ? 1 : -1
                    let y = frame.origin.y + (frame.size.height * factor)
                    UIView.animate(withDuration: duration, animations: {
                        self.tabBarController?.tabBar.frame = CGRect(x: frame.origin.x, y: y, width: frame.width, height: frame.height)
                    }) { (bool) in
                        //hide the tabbar after the animation in case ti has to be hidden
                        if (!(self.tabBarController?.tabBar.isHidden)!){
                            self.tabBarController?.tabBar.isHidden = hidden
                        }
                    }
                }
            }
        }
    }
}
