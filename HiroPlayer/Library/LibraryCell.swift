//
//  LibraryCell.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/14.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import UIKit

class LibraryCell: UICollectionViewCell {
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    override var isSelected: Bool{
        didSet{
            if self.isSelected {
                self.contentView.addBlurEffect()
            } else {
                self.contentView.removeBlurEffect()
            }
        }
    }
    
    func configure(_ item:PlaybackItem) {
        border(width: 1, color: .lightGray, cornerRadius: 5)
        
        artistLabel.text = item.artistName
        titleLabel.text = item.trackTitle
        
        favoriteButton.isSelected = LibraryManager.shared.isFavorite(item)
        
        let path = Const.Paths.documentsPath+"/"+item.artworkUrl
        thumbImageView.image = UIImage(contentsOfFile: path)
    }
}
