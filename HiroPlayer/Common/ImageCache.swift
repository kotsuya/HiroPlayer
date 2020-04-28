//
//  ImageCache.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/21.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import Foundation

final class ImageCache : NSCache<AnyObject, AnyObject> {
    static let shared = ImageCache()
    
}
