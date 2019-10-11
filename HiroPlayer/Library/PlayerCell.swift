//
//  PlayerCell.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/15.
//  Copyright © 2018年 nakazato. All rights reserved.
//

import UIKit

class PlayerCell: UITableViewCell {
    @IBOutlet weak var thumbImageView: UIImageView! {
        didSet {
            thumbImageView.border(width: 1, color: .lightGray)
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    func configure(_ item:PlaybackItem) {
        artistLabel.text = item.artistName
        titleLabel.text = item.trackTitle
        
        let path = Const.Paths.documentsPath+"/"+item.artworkUrl
        thumbImageView.image = UIImage(contentsOfFile: path)
    }
}
