//
//  TimeInterval+Extension.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/15.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import Foundation

extension TimeInterval {
    struct DateComponents {
        static let formatterPositional: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.minute,.second]
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad
            return formatter
        }()
    }
    var positionalTime: String {
        return DateComponents.formatterPositional.string(from: self) ?? ""
    }
}
