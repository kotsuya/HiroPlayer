//
//  AlbumCell.swift
//  HiroPlayer
//
//  Created by seunghwan.yoo on 2019/09/13.
//  Copyright © 2019 nakazato. All rights reserved.
//

import UIKit
import Firebase

class AlbumCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var folderImageView: UIImageView!
    @IBOutlet weak var downloadButton: UIButton! {
        didSet {
            downloadButton.border(width: 0, color: .lightGray, cornerRadius: 10)
        }
    }
    
}
