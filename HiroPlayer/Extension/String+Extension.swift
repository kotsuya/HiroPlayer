//
//  String+Extension.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/21.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import Foundation

extension String {
    func fileName() -> String {
        return NSURL(fileURLWithPath: self).deletingPathExtension?.lastPathComponent ?? ""
    }
    
    func fileExtension() -> String {
        return NSURL(fileURLWithPath: self).pathExtension ?? ""
    }
    
    var urlEncode: String {
        return self.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
}
