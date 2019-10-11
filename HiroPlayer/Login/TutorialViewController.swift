//
//  TutorialViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/12/21.
//  Copyright © 2018年 nakazato. All rights reserved.
//

import Foundation
import UIKit

enum TutorialStatus:Int {
    case none = 0
    case tutorialEnd = 1
    case tutorialError = 2
    
    //LoginViewController
    case createId = 3
    case signIn = 4
    case passwordReset = 5
    case provider = 6
    
    //LibraryViewController
//    case ownPartIcon = 5
//    case muteButton = 6
//    case playSpeedButton = 7
//    case partScoreButton = 8
//    case fullScoreButton = 9
    
    var message : String {
        switch self {
        case .createId:
            //등록하지 않은 경우 : 메일 주소, 암호 6 자 이상을 입력하고 아래의 Create 버튼을 누릅니다.
            return NSLocalizedString("Tutorial_Message_1", comment: "Create")
        case .signIn:
            //등록한 경우 : 메일 주소, 암호 6 자 이상을 입력하고 아래의 SignIn 버튼을 누릅니다.
            return NSLocalizedString("Tutorial_Message_2", comment: "SignIn")
        case .passwordReset:
            //패스워드 잊어버린 경우 : 메일 주소를 입력하고 아래의 Forgot Password 버튼을 누릅니다.
            return NSLocalizedString("Tutorial_Message_3", comment: "PasswordReset")
        case .provider:
            //등록했는지 모를 경우 : 메일 주소를 입력하고 아래의 ShowProviders 버튼을 누릅니다.
            return NSLocalizedString("Tutorial_Message_4", comment: "Provider")
        default:
            return ""
        }
    }
}

class Tutorial: NSObject {
    
    var status:TutorialStatus = .none    
    static let shared = Tutorial()
}

class TutorialViewController: UIViewController {
    
    var textStr: String?
    var textViewBackgroundColor:UIColor = .white
    
    var frameWidth = 270.0
    var frameHeight = 100.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myTextView: UITextView = UITextView(frame: CGRect(x:0.0, y:0.0, width:Double(frameWidth), height:frameHeight))
        myTextView.text = textStr
        
        let fontSize:CGFloat = 14
        myTextView.font = UIFont.systemFont(ofSize: fontSize)
        myTextView.textColor = UIColor.black
        myTextView.textAlignment = NSTextAlignment.center
        myTextView.backgroundColor = textViewBackgroundColor
        
        myTextView.isEditable = false
        
        myTextView.centerVertically()
        
        self.view.addSubview(myTextView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension UITextView {
    
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
    
}

