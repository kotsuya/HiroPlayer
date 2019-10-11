//
//  Array+Extension.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/21.
//  Copyright © 2018年 nakazato. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }
    
    func hasItems() -> Bool {
        return self.count > 0
    }
    
    var unique: [Element] {
        return reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
    }
    
    mutating func remove(_ value: Element) {
        if let i = self.firstIndex(of: value) {
            self.remove(at: i)
        }
    }
}
