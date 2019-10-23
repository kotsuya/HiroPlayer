//
//  TabBarController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/12/21.
//  Copyright © 2018年 nakazato. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
    var playBar: PlayBarView!
    
    var playerViewController: PlayerViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
        return vc
    }()
    
    let notificationCenter = NotificationCenter.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.barTintColor = .white
        
        var bottomPadding:CGFloat = 0
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            bottomPadding = window!.safeAreaInsets.bottom
        }
        
        playBar = PlayBarView(frame: CGRect(x: 0, y: tabBar.frame.origin.y - (Const.MusicPlayBarHeight+bottomPadding), width: view.bounds.width, height: Const.MusicPlayBarHeight))
        view.insertSubview(playBar, belowSubview: tabBar)        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        playBar.addGestureRecognizer(tap)
        
        playBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        notificationCenter.addObserver(self, selector: #selector(onTrackChanged), name: NSNotification.Name(rawValue: AudioPlayerOnTrackChangedNotification), object: nil)
        notificationCenter.addObserver(self, selector: #selector(onPlaybackStateChanged), name: NSNotification.Name(rawValue: AudioPlayerOnPlaybackStateChangedNotification), object: nil)
        
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        presentPlayerView(nil)
    }
    
    func presentPlayerView(_ item: PlaybackItem?) {
        if let item = item {
            playBar.player.playItem(item)
        }
                
        present(playerViewController, animated: true, completion: {
            self.playBar.isHidden = false
        })
    }
    
    //MARK: - Notifications
    
    @objc func onTrackChanged() {
        playBar.updatePlayBar()
    }
    
    @objc func onPlaybackStateChanged() {
        playBar.updatePlayBar()
    }
}
