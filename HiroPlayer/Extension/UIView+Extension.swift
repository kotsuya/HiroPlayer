//
//  UIView+Extension.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/14.
//  Copyright © 2018年 nakazato. All rights reserved.
//

import UIKit

extension UIView {
    func border(width: CGFloat, color: UIColor, cornerRadius: CGFloat = 5.0) {
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }
    
    func addBlurEffect() {
        let effectView = UIView()
        effectView.frame = self.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        effectView.tag = 99 //magic number
        self.addSubview(effectView)
    }
    
    func removeBlurEffect() {
        let effectView = self.subviews.filter{$0.tag == 99}
        effectView.forEach{ view in
            view.removeFromSuperview()
        }
    }
    
    func innerShadow() {
        let path = UIBezierPath(rect: CGRect(x: -5.0, y: -5.0, width: self.bounds.size.width + 5.0, height: 5.0 ))
        let innerLayer = CALayer()
        innerLayer.frame = self.bounds
        innerLayer.masksToBounds = true
        innerLayer.shadowColor = UIColor.black.cgColor
        innerLayer.shadowOffset = CGSize(width: 2.5, height: 2.5)
        innerLayer.shadowOpacity = 0.5
        innerLayer.shadowPath = path.cgPath
        self.layer.addSublayer(innerLayer)
    }
}

extension UICollectionViewCell {
    public func setShadow() {
        self.addCardStyleRoundRectCorners()
        self.addCardStyleShadow()
    }
    
    /// ビューに影を追加する
    func addCardStyleShadow() {
        layer.masksToBounds = false
        layer.shadowRadius = 1
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0.5)
        layer.shadowOpacity = 0.3
    }
    
    /// ビューに角丸を追加する
    func addCardStyleRoundRectCorners() {
        layer.masksToBounds = true
        layer.cornerRadius = 5
    }
}

extension UITableView {

    func cellCount() -> Int {
        let sections: Int = self.numberOfSections
        var rows: Int = 0
        
        for i in 0..<sections {
            rows += self.numberOfRows(inSection: i)
        }
        return rows
    }
}
