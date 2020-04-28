//
//  AudioPlayer.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/15.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer
import Firebase

let AudioPlayerOnTrackChangedNotification = "AudioPlayerOnTrackChangedNotification"
let AudioPlayerOnPlaybackStateChangedNotification = "AudioPlayerOnPlaybackStateChangedNotification"

enum RepeatType : String {
    case noRepeat
    case oneRepeat
    case allRepeat
}

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    //MARK: - Vars
    
    var audioPlayer: AVAudioPlayer?
    open var playbackItems: [PlaybackItem]? {
        return LibraryManager.shared.getPlaybackItems()
    }
    open var currentPlaybackItem: PlaybackItem?
    open var nextPlaybackItem: PlaybackItem? {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return nil }
       
        let nextItemIndex = playbackItems.firstIndex(of: currentPlaybackItem)! + 1
        if nextItemIndex >= playbackItems.count {
            if repeatType == .noRepeat  { return nil }
            else if repeatType == .oneRepeat  { return currentPlaybackItem }
            else { return playbackItems.first }
        }
        
        return playbackItems[nextItemIndex]
    }
    open var previousPlaybackItem: PlaybackItem? {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return nil }
        
        let previousItemIndex = playbackItems.firstIndex(of: currentPlaybackItem)! - 1
        if previousItemIndex < 0 {
            if repeatType == .noRepeat  { return nil }
            else if repeatType == .oneRepeat  { return currentPlaybackItem }
            else { return playbackItems.last }
        }
        
        return playbackItems[previousItemIndex]
    }
    var nowPlayingInfo: [String : AnyObject]?
    
    open var currentTime: TimeInterval? {
        return self.audioPlayer?.currentTime
    }
    
    open var duration: TimeInterval? {
        return self.audioPlayer?.duration
    }
    
    open var isPlaying: Bool {
        return self.audioPlayer?.isPlaying ?? false
    }
    
    var repeatType: RepeatType = .allRepeat
    
    //MARK: - Dependencies
    
    let audioSession: AVAudioSession
    let commandCenter: MPRemoteCommandCenter
    let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    let notificationCenter: NotificationCenter
    
    //MARK: - Init
    
    typealias AudioPlayerDependencies = (audioSession: AVAudioSession, commandCenter: MPRemoteCommandCenter, nowPlayingInfoCenter: MPNowPlayingInfoCenter, notificationCenter: NotificationCenter)
    
    init(dependencies: AudioPlayerDependencies) {
        self.audioSession = dependencies.audioSession
        self.commandCenter = dependencies.commandCenter
        self.nowPlayingInfoCenter = dependencies.nowPlayingInfoCenter
        self.notificationCenter = dependencies.notificationCenter
        
        super.init()
        
        try? self.audioSession.setCategory(.playback, mode: .default, options: .defaultToSpeaker)
        try? self.audioSession.setActive(true)
        
        self.configureCommandCenter()
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListener(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    @objc func audioRouteChangeListener(_ notification:Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                return
        }
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs where output.portType == AVAudioSession.Port.headphones {
                //print("headphone plugged in")
                break
            }
        case .oldDeviceUnavailable:
            if self.isPlaying {
                self.pause()
            }
//            if let previousRoute =
//                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
//                for output in previousRoute.outputs where output.portType == AVAudioSession.Port.headphones {
//                    //print("headphone pulled out")
//                    if self.isPlaying {
//                        self.pause()
//                    }
//                    break
//                }
//            }
        default: ()
        }
        
    }
    
    //MARK: - Playback Commands
    
    func playItem(_ playbackItem: PlaybackItem) {
        let localURL = URL(fileURLWithPath: Const.Paths.documentsPath+"/\(playbackItem.trackUrl)")
        guard let audioPlayer = try? AVAudioPlayer(contentsOf: localURL) else {
            self.endPlayback()
            return
        }
        
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
        self.audioPlayer = audioPlayer
        
        self.currentPlaybackItem = playbackItem
        
        self.updateNowPlayingInfoForCurrentPlaybackItem()
        self.updateCommandCenter()
        
        self.notifyOnTrackChanged()
    }
    
    open func togglePlayPause() {
        if self.isPlaying {
            self.pause()
        }
        else {
            self.play()
        }
    }
    
    open func play() {
        self.audioPlayer?.play()
        self.updateNowPlayingInfoElapsedTime()
        self.notifyOnPlaybackStateChanged()
    }
    
    open func pause() {
        self.audioPlayer?.pause()
        self.updateNowPlayingInfoElapsedTime()
        self.notifyOnPlaybackStateChanged()
    }
    
    open func nextTrack() {
        guard let nextPlaybackItem = self.nextPlaybackItem else { return }
        self.playItem(nextPlaybackItem)
        self.updateCommandCenter()
    }
    
    open func previousTrack() {
        if isPlaying, let currentTime = audioPlayer?.currentTime, currentTime > 3 {
            seekTo(0.0)
        } else {
            guard let previousPlaybackItem = self.previousPlaybackItem else { return }
            self.playItem(previousPlaybackItem)
            self.updateCommandCenter()
        }
    }
    
    open func seekTo(_ timeInterval: TimeInterval) {
        self.audioPlayer?.currentTime = timeInterval
        self.updateNowPlayingInfoElapsedTime()
    }
    
    //MARK: - Command Center
    
    func updateCommandCenter() {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return }
        if repeatType == .allRepeat {
            self.commandCenter.previousTrackCommand.isEnabled = true
            self.commandCenter.nextTrackCommand.isEnabled = true
        } else {
            self.commandCenter.previousTrackCommand.isEnabled = currentPlaybackItem != playbackItems.first!
            self.commandCenter.nextTrackCommand.isEnabled = currentPlaybackItem != playbackItems.last!
        }
    }
    
    func configureCommandCenter() {
        self.commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.play()
            return .success
        })
        
        self.commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.pause()
            return .success
        })
        
        self.commandCenter.nextTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.nextTrack()
            return .success
        })
        
        self.commandCenter.previousTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.previousTrack()
            return .success
        })
        
        //iPhone-earphone play-stop button
        self.commandCenter.togglePlayPauseCommand.addTarget(handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.togglePlayPause()
            return .success
        })
    }
    
    //MARK: - Now Playing Info
    
    func updateNowPlayingInfoForCurrentPlaybackItem() {
        guard let audioPlayer = self.audioPlayer, let currentPlaybackItem = self.currentPlaybackItem else {
            self.configureNowPlayingInfo(nil)
            return
        }
        
        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.trackTitle,
                              MPMediaItemPropertyAlbumTitle: currentPlaybackItem.trackTitle,
                              MPMediaItemPropertyArtist: currentPlaybackItem.artistName,
                              MPMediaItemPropertyPlaybackDuration: audioPlayer.duration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float)] as [String : Any]
        
        if let image = UIImage(contentsOfFile: Const.Paths.documentsPath+"/"+currentPlaybackItem.artworkUrl) {
            if #available(iOS 10.0, *) {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
                    return image
                })
            } else {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
            }
        }
        
        self.configureNowPlayingInfo(nowPlayingInfo as [String : AnyObject]?)
        
        self.updateNowPlayingInfoElapsedTime()
    }
    
    func updateNowPlayingInfoElapsedTime() {
        guard var nowPlayingInfo = self.nowPlayingInfo, let audioPlayer = self.audioPlayer else { return }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: audioPlayer.currentTime as Double);
        
        self.configureNowPlayingInfo(nowPlayingInfo)
    }
    
    func configureNowPlayingInfo(_ nowPlayingInfo: [String: AnyObject]?) {
        self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }
    
    //MARK: - AVAudioPlayerDelegate
    
    open func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.endPlayback()
//        if self.nextPlaybackItem == nil {
//            self.endPlayback()
//        }
//        else {
//            self.nextTrack()
//        }
    }
    
    func endPlayback() {
        if repeatType == .oneRepeat {
            guard let currentPlaybackItem = currentPlaybackItem else { return }
            self.playItem(currentPlaybackItem)
            self.updateCommandCenter()
        } else {
            self.nextTrack()
        }
        
//        self.currentPlaybackItem = nil
//        self.audioPlayer = nil
//
//        self.updateNowPlayingInfoForCurrentPlaybackItem()
//        self.notifyOnTrackChanged()
    }
    
    open func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        self.notifyOnPlaybackStateChanged()
    }
    
    open func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        if AVAudioSession.InterruptionOptions(rawValue: UInt(flags)) == .shouldResume {
            self.play()
        }
    }
    
    //MARK: - Convenience
    
    func notifyOnPlaybackStateChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: AudioPlayerOnPlaybackStateChangedNotification), object: self)
    }
    
    func notifyOnTrackChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: AudioPlayerOnTrackChangedNotification), object: self)
    }
    
    //MARK: -
    
}
