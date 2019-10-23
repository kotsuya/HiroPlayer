//
//  PlayBarView.swift
//  HiroPlayer
//
//  Created by Yoo on 2019/04/29.
//  Copyright © 2019 nakazato. All rights reserved.
//

import Foundation
import UIKit

class PlayBarView: UIView {

    @IBOutlet weak var thumbnailView: UIImageView! {
        didSet {
            thumbnailView.border(width: 1, color: .lightGray)
        }
    }
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var player: AudioPlayer!
    
    override init(frame: CGRect){
        super.init(frame: frame)
        loadNib()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
    }
    
    func loadNib(){
        let view = Bundle.main.loadNibNamed("PlayBarView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        view.border(width: 1.0, color: .black, cornerRadius: 0)
        self.addSubview(view)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        player = appDelegate.player
    }
    
    func setButton(_ isPlay: Bool, _ prevIsEnabled: Bool, _ nextIsEnabled: Bool) {
        playPauseButton.isSelected = isPlay
        prevButton.isEnabled = prevIsEnabled
        nextButton.isEnabled = nextIsEnabled
    }
        
    func updatePlayBar() {
        if let item = self.player.currentPlaybackItem {
            let path = Const.Paths.documentsPath+"/"+item.artworkUrl
            if let img = UIImage(contentsOfFile: path) {
                thumbnailView.image = img
            }
            titleLabel.text = item.trackTitle
        }
        
        playPauseButton.isSelected = self.player.isPlaying
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        switch sender.tag {
            case 0: //play
                player.togglePlayPause()
            case 1: //prev
                player.previousTrack()
            case 2: //next
                player.nextTrack()
            default:break;
        }
        updatePlayBar()
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        close()
    }
    
    func close() {
        if player.isPlaying { player.pause() }
        isHidden = true
    }
    
}
