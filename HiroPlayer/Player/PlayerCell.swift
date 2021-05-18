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
        
        if item.lyrics == nil {
            lyricsButton.setTitle(nil, for: .normal)
            lyricsButton.setImage(UIImage(named: "refresh"), for: .normal)
            lyricsButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            lyricsButton.imageView?.contentMode = .scaleAspectFit
        } else {
            lyricsButton.setTitle(NSLocalizedString("lyrics", comment: "lyrics"), for: .normal)
            lyricsButton.setImage(nil, for: .normal)
        }
    }
}
