//
//  LicenseViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/24.
//  Copyright © 2018 Yoo. All rights reserved.
//

import UIKit
import WebKit

class LicenseViewController: UIViewController {
    
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "License"
        
        webView = WKWebView(frame:CGRect(x:0, y:0, width:self.view.bounds.size.width, height:self.view.bounds.size.height))

        let urlString = "https://www.google.com/"
        let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        
        let url = NSURL(string: encodedUrlString!)
        let request = NSURLRequest(url: url! as URL)
        
        webView.load(request as URLRequest)
        webView.navigationDelegate = self
        
        self.view.addSubview(webView)
    }
}

extension LicenseViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        showSpinner {
            print("遷移開始")
        }        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideSpinner {
            print("読み込み完了")
            print(webView.title as Any)
        }
    }
}
