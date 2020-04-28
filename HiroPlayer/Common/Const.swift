//
//  Const.swift
//  HiroPlayer
//
//  Created by Yoo on 2019/04/29.
//  Copyright © 2019 Yoo. All rights reserved.
//

import Foundation
import UIKit

struct Const {
    static let MusicDetailTopPadding: CGFloat = 35
    static let MusicPlayBarHeight: CGFloat = 70
    static let StatusBarHeight = UIApplication.shared.statusBarFrame.height
    static let HomeMinScale: CGFloat = 0.95
    
    struct Paths {
        static let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    static let hasNotch: Bool = {
        // 今の所safeAreaInset.topが44以上なぐらいしか判断材料がないのでこれで判断
        return UIApplication.shared.keyWindow!.safeAreaInsets.top >= 44
    }()
}


