//
//  SearchCell.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/14.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class SearchCell: UITableViewCell {
    @IBOutlet weak var thumbImageView: UIImageView! {
        didSet {
            thumbImageView.border(width: 1, color: .lightGray)
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton! {
        didSet {
            downloadButton.border(width: 0, color: .lightGray, cornerRadius: 10)
        }
    }
    @IBOutlet weak var barsView: UIView! {
        didSet {
            barsView.border(width: 0, color: .lightGray)
        }
    }
    @IBOutlet weak var barsImageView: UIImageView!
    
    func updateAccessoryView(_ isPlaying: Bool) {
        if isPlaying {
            var images = [UIImage]()
            for i in 1...9 {
                let image = UIImage(named: "bars\(i)")?.imageWithColor(.white)
                images.append(image!)
            }
            
            barsImageView.animationImages = images
            barsImageView.animationDuration = 1
            barsImageView.startAnimating()
            barsImageView.alpha = 1.0
            barsView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        } else {
            barsImageView.stopAnimating()
            barsImageView.alpha = 0.0
            barsView.backgroundColor = .clear
        }
    }

    private func updateUI(_ item:PlaybackItem) {
        titleLabel.text = "[\(item.downloadCount)] \(item.trackTitle)"
        artistLabel.text = item.description
        albumLabel.text = item.artistName
        
        if item.release == "private" {
            self.backgroundColor = UIColor(hex: "#f8f8f8")
        }
    }
    
    func configure_ed(_ item:PlaybackItem) {
        updateUI(item)
        let path = Const.Paths.documentsPath+"/"+item.artworkUrl
        thumbImageView.image = UIImage(contentsOfFile: path)
    }
    
    func configure_able(_ item:PlaybackItem) {
        updateUI(item)
        let cache = ImageCache.shared
        if let img = cache.object(forKey: item.artworkUrl as AnyObject) {
            thumbImageView.image = img as? UIImage
        } else {
            thumbImageView.kf.indicatorType = .activity
            thumbImageView.kf.setImage(
                with: URL(string: item.artworkWebUrl),
                placeholder: UIImage(named: "noImage"),
                options: [.cacheMemoryOnly]) { result in
                    switch result {
                    case .success(let value):
                        cache.setObject(value.image, forKey: item.artworkUrl as AnyObject)
                    case .failure(let error):
                        print("Job failed: \(error.localizedDescription)")
                    }
            }
        }
    }
}

class PaddingLabel: UILabel {
    
    @IBInspectable var padding: UIEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 5)
    
    override func drawText(in rect: CGRect) {
        let newRect = rect.inset(by: padding)
        super.drawText(in: newRect)
    }
    
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += padding.top + padding.bottom
        contentSize.width += padding.left + padding.right
        return contentSize
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var contentSize = super.sizeThatFits(size)
        contentSize.width += padding.left + padding.right
        contentSize.height += padding.top + padding.bottom
        return contentSize
    }
    
}
