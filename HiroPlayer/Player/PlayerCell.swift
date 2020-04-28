//
//  PlayerCell.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/15.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import UIKit

class PlayerCell: UITableViewCell {
    @IBOutlet weak var thumbImageView: UIImageView! {
        didSet {
            thumbImageView.border(width: 1, color: .lightGray)
        }
    }
    @IBOutlet weak var lyricsButton: UIButton! {
        didSet {
            lyricsButton.border(width: 1, color: .lightGray)
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    func configure(_ item:PlaybackItem, _ indexPath: IndexPath) {
        artistLabel.text = item.artistName
        titleLabel.text = item.trackTitle
        
        let path = Const.Paths.documentsPath+"/"+item.artworkUrl
        thumbImageView.image = UIImage(contentsOfFile: path)
                
        lyricsButton.tag = indexPath.row
        lyricsButton.isHidden = (item.lyrics == nil)
    }
}
