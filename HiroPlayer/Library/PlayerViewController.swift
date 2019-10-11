//
//  PlayerViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/14.
//  Copyright © 2018年 nakazato. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase

protocol PlayerViewControllerDelegate: class {
    func update(_ progress: CGFloat)
}

class PlayerViewController: UIViewController, AVAudioPlayerDelegate {
    
    weak var delegate: PlayerViewControllerDelegate?
    
    private var originFrame = CGRect(x: 0, y: 0, width: 0, height: 1)
    
    deinit {
        notificationCenter.removeObserver(self)
        timer?.invalidate()
    }
    
    @IBOutlet weak var thumbImageView: UIImageView! {
        didSet {
            thumbImageView.border(width: 1, color: .black)
        }
    }
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var remainingLabel: UILabel!
    
    @IBOutlet weak var prevButton: UIButton! {
        didSet {
            prevButton.border(width: 1, color: .lightGray)
        }
    }
    @IBOutlet weak var playButton: UIButton! {
        didSet {
            playButton.border(width: 1, color: .lightGray)
        }
    }
    @IBOutlet weak var nextButton: UIButton! {
        didSet {
            nextButton.border(width: 1, color: .lightGray)
        }
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView(frame: CGRect.zero)
        }
    }
    
    @IBOutlet weak var headButton: UIButton! {
        didSet {
            headButton.border(width: 0, color: .lightGray, cornerRadius: 2)
        }
    }
    
    var player: AudioPlayer!
    let notificationCenter = NotificationCenter.default
    
    var timer: Timer?
    
    //MARK: - Playlist Items
        
    var firstItem: PlaybackItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Player", comment: "Player")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        player = appDelegate.player
        
        player.playItem(firstItem)
        
        configureTimer()
        
        if Const.hasNotch {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
            view.addGestureRecognizer(pan)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        notificationCenter.addObserver(self, selector: #selector(onTrackChanged), name: NSNotification.Name(rawValue: AudioPlayerOnTrackChangedNotification), object: nil)
        notificationCenter.addObserver(self, selector: #selector(onPlaybackStateChanged), name: NSNotification.Name(rawValue: AudioPlayerOnPlaybackStateChangedNotification), object: nil)
        
        tableView.reloadData()
        
        updateView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateTableViewSelect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        notificationCenter.removeObserver(self, name: NSNotification.Name(rawValue: AudioPlayerOnTrackChangedNotification), object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name(rawValue: AudioPlayerOnPlaybackStateChangedNotification), object: nil)
    }
    
    //MARK: - Notifications
    
    @objc func onTrackChanged() {
        if !self.isViewLoaded { return }
        
        if self.player.currentPlaybackItem == nil {
            return
        }
        
        self.updateView()
    }
    
    @objc func onPlaybackStateChanged() {
        if !self.isViewLoaded { return }
        
        self.updateControls()
    }
    
    //MARK: - Configuration
    
    func configureTimer() {
        self.timer = Timer.every(0.1.seconds) { [weak self] in
            guard let sself = self else { return }
            
            if !sself.slider.isTracking {
                sself.slider.value = Float(sself.player.currentTime ?? 0)
            }
            
            sself.updateTimeLabels()
        }
    }
    
    @IBAction func play(_ sender: UIButton) {
        player.togglePlayPause()
    }
    
    @IBAction func prevPlay(_ sender: UIButton) {
        player.previousTrack()
    }
    
    @IBAction func nextPlay(_ sender: UIButton) {
        player.nextTrack()
    }
    
    @IBAction func sliderValueChanged(_ sender: AnyObject) {
        player.seekTo(Double(slider.value))
    }
    
    
    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func repeatAction(_ sender: UIBarButtonItem) {
        let repeatType = player.repeatType
        var image = UIImage(named: "repeatAll")
        if repeatType == .noRepeat {
            player.repeatType = .oneRepeat
            image = UIImage(named: "repeatOne")
        } else if repeatType == .oneRepeat {
            player.repeatType = .allRepeat
        } else if repeatType == .allRepeat {
            player.repeatType = .noRepeat
            image = UIImage(named: "repeat")
        }        
        sender.image = image
    }
    
    
    //MARK: - Update
    
    func updateView() {
        updateArtworkImageView()
        updateSlider()
        updateTimeLabels()
        updateControls()
        updateTableViewSelect()
    }
    
    func updateArtworkImageView() {
        if let item = self.player.currentPlaybackItem {
            let path = Const.Paths.documentsPath+"/"+item.artworkUrl
            if let img = UIImage(contentsOfFile: path) {
                thumbImageView.image = img
            }
        }
    }
    
    func updateSlider() {
        slider.minimumValue = 0
        slider.maximumValue = Float(player.duration ?? 0)
    }
    
    func updateTimeLabels() {
        if let currentTime = player.currentTime, let duration = player.duration {
            currentLabel.text = humanReadableTimeInterval(currentTime)
            remainingLabel.text = "-" + humanReadableTimeInterval(duration - currentTime)
        } else {
            currentLabel.text = ""
            remainingLabel.text = ""
        }
    }
    
    func updateControls() {
        playButton.isSelected = player.isPlaying
        nextButton.isEnabled = player.nextPlaybackItem != nil
        prevButton.isEnabled = player.previousPlaybackItem != nil
    }
    
    func updateTableViewSelect() {
        // TODO : want to make the code more simply...        
        if let playItem = player.currentPlaybackItem,
            tableView.cellCount() == LibraryManager.shared.getPlaybackItems().count,
            let row = LibraryManager.shared.getPlaybackItems().indexes(of: playItem).first {
            tableView.selectRow(at: IndexPath(row: row, section: 0),
                                animated: true,
                                scrollPosition: .middle)
        }
    }
    
    //MARK: - Convenience
    
    func humanReadableTimeInterval(_ timeInterval: TimeInterval) -> String {
        let timeInt = Int(round(timeInterval))
        let (hh, mm, ss) = (timeInt / 3600, (timeInt % 3600) / 60, (timeInt % 3600) % 60)
        
        let hhString: String? = hh > 0 ? String(hh) : nil
        let mmString = (hh > 0 && mm < 10 ? "0" : "") + String(mm)
        let ssString = (ss < 10 ? "0" : "") + String(ss)
        
        return (hhString != nil ? (hhString! + ":") : "") + mmString + ":" + ssString
    }
    
    func animateContentChange(_ transitionSubtype: String, layer: CALayer) {
        let transition = CATransition()
        
        transition.duration = 0.25
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype(rawValue: transitionSubtype)
        
        layer.add(transition, forKey: kCATransition)
    }
    
    func animateNoPreviousTrackBounce(_ layer: CALayer) {
        animateBounce(fromValue: NSNumber(value: 0 as Int), toValue: NSNumber(value: 25 as Int), layer: layer)
    }
    
    func animateNoNextTrackBounce(_ layer: CALayer) {
        animateBounce(fromValue: NSNumber(value: 0 as Int), toValue: NSNumber(value: -25 as Int), layer: layer)
    }
    
    func animateBounce(fromValue: NSNumber, toValue: NSNumber, layer: CALayer) {
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = 0.1
        animation.repeatCount = 1
        animation.autoreverses = true
        animation.isRemovedOnCompletion = true
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        layer.add(animation, forKey: "Animation")
    }
    
    // MARK: -
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        let viewTransition = gesture.translation(in: view)
        let progress = viewTransition.y / (originFrame.height - Const.MusicPlayBarHeight)
        switch gesture.state {
        case .began:
            originFrame = view.frame
        case .changed:
            update(progress)
        case .cancelled:
            break
        case .ended:
            if progress > 0.2 {
                dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.2 + 0.2 * Double(progress), delay: 0, options: .curveEaseInOut, animations: {
                    self.delegate?.update(0)
                    self.view.frame = self.originFrame
                })
            }
            break
        default:
            break
        }
    }
    
    private func update(_ progress: CGFloat) {
        delegate?.update(progress)
        view.frame = CGRect(x: 0, y: originFrame.origin.y + (originFrame.height - Const.MusicPlayBarHeight) * progress, width: view.bounds.width, height: view.bounds.height)
    }
}

extension PlayerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let count = LibraryManager.shared.getPlaybackItems().count
        return  "\(NSLocalizedString("Player_list", comment: "Player List")) [ \(count) ]"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LibraryManager.shared.getPlaybackItems().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as! PlayerCell
        cell.configure(LibraryManager.shared.getPlaybackItems()[indexPath.row])
        return cell
    }
}

extension PlayerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player.playItem(LibraryManager.shared.getPlaybackItems()[indexPath.row])
        player.updateCommandCenter()
    }
}
