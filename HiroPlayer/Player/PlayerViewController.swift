//
//  PlayerViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/14.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import SnapKit
import UIKit
import AVFoundation
import Firebase

class PlayerViewController: UIViewController, AVAudioPlayerDelegate {
    
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
        
        configureTimer()
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
    
    @IBAction func lyricsAction(_ sender: UIButton) {
        let item = LibraryManager.shared.getPlaybackItems()[sender.tag]
        let title = NSLocalizedString("lyrics", comment: "lyrics")
        
        if sender.currentTitle == title {
            guard var lyrics = item.lyrics else { return }
                    
            while let range = lyrics.range(of: "\\n") {
                lyrics.replaceSubrange(range, with: "\n")
            }
            
            let alert = UIAlertController(title: item.trackTitle, message: "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
            
            let textView = UITextView()
            textView.text = lyrics
            textView.font = UIFont.systemFont(ofSize: 17)
            textView.layer.borderColor = UIColor.lightGray.cgColor
            textView.layer.borderWidth = 0.5
            textView.layer.cornerRadius = 6
            textView.isEditable = false

            // textView を追加して Constraints を追加
            alert.view.addSubview(textView)
            textView.snp.makeConstraints { make in
                make.top.equalTo(50)
                make.left.equalTo(10)
                make.right.equalTo(-10)
                make.bottom.equalTo(-60)
            }
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            }))
            
            self.present(alert, animated: true) {
            }
        } else {
            self.showSpinner {
                Helper.shared.getItem(item) { [weak self] item in
                    guard let item = item else { return }
                    if let lyrics = item.lyrics, lyrics.count > 0 {
                        var items = LibraryManager.shared.getPlaybackItems()
                        if let row = items.firstIndex(where: {$0.uid == item.uid}) {
                            items[row] = item
                            LibraryManager.shared.setPlaybackItem(items)
                            let indexPath = IndexPath(row: sender.tag, section: 0)
                            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    } else {
                        self?.showMessagePrompt("There is no lyrics.")
                    }
                }
                self.hideSpinner { }
            }
        }
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
        
        //PlaybackItem
        let item = LibraryManager.shared.getPlaybackItems()[indexPath.row]
        cell.configure(item, indexPath)
        return cell
    }
}

extension PlayerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player.playItem(LibraryManager.shared.getPlaybackItems()[indexPath.row])
        player.updateCommandCenter()
    }
}
