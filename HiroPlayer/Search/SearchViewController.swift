//
//  SearchViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/14.
//  Copyright © 2018年 nakazato. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import AVFoundation

enum SearchType: Int {
    case trackTitle = 0
    case artistName
    
    public var description: String {
        switch self {
        case .trackTitle:
            return "trackTitle"
        case .artistName:
            return "artistName"
        }
    }
}

enum ListType: Int {
    case all = 0
    case purchase
    case available
    
    public var description: String {
        switch self {
        case .all:
            return NSLocalizedString("All", comment: "All")
        case .purchase:
            return NSLocalizedString("Purchase", comment: "Purchase")
        case .available:
            return NSLocalizedString("Available", comment: "Available")
        }
    }
}

class SearchViewController: UIViewController {
    
    @IBOutlet weak var bottomConst: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var listTypeButton: UIBarButtonItem! {
        didSet {
            listTypeButton.title = listType.description
        }
    }
    
    let ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    var playbackItems = [PlaybackItem]()
    var allPlaybackItems = [PlaybackItem]()
    var searchType: SearchType = .trackTitle
    var listType: ListType = .all
    
    var newPlaybackItems = [PlaybackItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Search", comment: "Search")
        
        setTableViewItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchBar.text = ""
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        listType = .all
        listTypeButton.title = listType.description
    }
    
    @IBAction func listTypeAction(_ sender: UIBarButtonItem) {
        if listType == .all {
            listType = .purchase
            playbackItems = allPlaybackItems.filter { Helper.shared.isFileExist($0) }
        } else if listType == .purchase {
            listType = .available
            playbackItems = allPlaybackItems.filter { !Helper.shared.isFileExist($0) }
        } else if listType == .available {
            listType = .all
            playbackItems = allPlaybackItems
        }
        sender.title = listType.description
        tableView.reloadData()
    }
    
    @IBAction func downloadAction(_ sender: UIButton) {
        guard let btnTitle = sender.currentTitle else { return }
        
        let index = int2IndexPath(sender.tag)
        var playItem: PlaybackItem = playbackItems[index.row]
        if isNewItem(index) {
            playItem = newPlaybackItems[index.row]
        }
        
        var title = "Purchase"
        var message = NSLocalizedString("Purchase_Confirm_Message", comment: "Message")
        if btnTitle == "Delete" {
            title = "Delete"
            message = "\(playItem.artistName),\(playItem.trackTitle) Delete?"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: title, style: .default) { (UIAlertAction) in
            if btnTitle == "Delete" {
                self.delete(index, playItem)
            } else {
                self.download(index, playItem)
            }
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func download(_ indexPath: IndexPath, _ playItem: PlaybackItem) {
        //playItem.trackUrl : "music/ぱなまん/曖昧劣情Lover/lover.m4a"
        let localTrackURL = URL(fileURLWithPath: Const.Paths.documentsPath+"/"+playItem.trackUrl)
        let localImageURL = URL(fileURLWithPath: Const.Paths.documentsPath+"/"+playItem.artworkUrl)
        let trackUrlRef = storageRef.child(playItem.trackUrl)
        let trackImageRef = storageRef.child(playItem.artworkUrl)
        
        showSpinner {
            _ = trackUrlRef.write(toFile: localTrackURL) { url, error in
                if let error = error {
                    print("error:\(error)")
                    self.hideSpinner { }
                } else {
                    _ = trackImageRef.write(toFile: localImageURL) { url, error in
                        if let error = error {
                            print("error:\(error)")
                            self.hideSpinner { }
                        } else {
                            self.hideSpinner { self.showAlert(indexPath, playItem) }
                        }
                    }
                }
            }
        }
    }
    
    private func delete(_ indexPath: IndexPath, _ playItem: PlaybackItem) {
        let localURL = "\(Const.Paths.documentsPath)/music/\(playItem.artistName)/\(playItem.trackTitle)"
        do {
            try FileManager.default.removeItem(atPath: localURL)
            let uid = playItem.uid
            self.ref.child("music/"+uid).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                let downloadCnt = Helper.shared.setDownloadCount(value, false, uid)
                if self.isNewItem(indexPath) {
                    self.newPlaybackItems[indexPath.row].downloadCount = downloadCnt
                } else {
                    self.playbackItems[indexPath.row].downloadCount = downloadCnt
                }
                LibraryManager.shared.removeLibrary(playItem)
                LibraryManager.shared.removeFavorite(playItem)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }) { (error) in
                print(error.localizedDescription)
            }
        } catch {
            print("error")
        }
    }
    
    private func showAlert(_ indexPath: IndexPath, _ playItem: PlaybackItem) {
        let alert = UIAlertController(title: "", message: "Download Success!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
            let uid = playItem.uid
            self.ref.child("music/"+uid).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                let downloadCnt = Helper.shared.setDownloadCount(value, true, uid)
                if self.isNewItem(indexPath) {
                    self.newPlaybackItems[indexPath.row].downloadCount = downloadCnt
                } else {
                    self.playbackItems[indexPath.row].downloadCount = downloadCnt
                }
                LibraryManager.shared.addLibrary(playItem)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }) { (error) in
                print(error.localizedDescription)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }

    private func setTableViewItems() {
        self.ref.child("music/").observe(.value, with: { (snapshot) in
            self.showSpinner {
                var tmpPlaybackItems = [PlaybackItem]()
                self.newPlaybackItems.removeAll()

                if let value = snapshot.value as? NSDictionary {
                    for key in value.allKeys {
                        guard let item = value[key] else { return }
                        do {
                            let playbackItem = try FirebaseDecoder().decode(PlaybackItem.self, from: item)
                            if let createdAt = playbackItem.createdAt {
                                let timeInterval = createdAt.timeIntervalSinceReferenceDate
                                let date = Int(timeInterval).dateFromMilliseconds()
                                if date.isInDayBeforeYesterday {
                                    self.newPlaybackItems.append(playbackItem)
                                } else {
                                    if playbackItem.release == "private" {
                                        if playbackItem.addBy == Auth.auth().currentUser?.email {
                                            tmpPlaybackItems.append(playbackItem)
                                        }
                                    } else {
                                        tmpPlaybackItems.append(playbackItem)
                                    }
                                }
                            }
                        } catch let error {
                            print(error)
                        }
                    }
                    if self.newPlaybackItems.hasItems() {
                        self.newPlaybackItems.sort(by: {$0.downloadCount > $1.downloadCount})
                    }
                    if tmpPlaybackItems != self.playbackItems  {
                        self.playbackItems = tmpPlaybackItems
                        self.playbackItems.sort(by: {$0.downloadCount > $1.downloadCount})
                        self.allPlaybackItems = self.playbackItems
                        self.tableView.reloadData()
                    }
                }
                    self.hideSpinner { }
                }
            }) { (error) in
                self.showMessagePrompt(error.localizedDescription)
                self.hideSpinner { }
        }
    }
    
    private func indexPath2Int(_ indexPath: IndexPath) -> Int {
        return indexPath.row*1000+indexPath.section
    }
    
    private func int2IndexPath(_ tag: Int) -> IndexPath {
        return IndexPath(item: tag/1000, section: tag%1000)
    }
}

extension SearchViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if newPlaybackItems.hasItems() {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if newPlaybackItems.hasItems() {
            if section == 0 {
                return NSLocalizedString("New", comment: "New") + "(\(newPlaybackItems.count))"
            }
        }
        return NSLocalizedString("Ranking", comment: "Ranking") + "(\(playbackItems.count))"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if newPlaybackItems.hasItems() {
            if section == 0 {
                return newPlaybackItems.count
            }
        }
        return playbackItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchCell
        var item: PlaybackItem
        if isNewItem(indexPath) {
            item = newPlaybackItems[indexPath.row]
        } else {
            item = playbackItems[indexPath.row]
        }
        
        // パフォーマンスの理由でCell resetはtableView(_:cellForRowAt:)の中に書くのが良い(Apple Document)
        cell.thumbImageView.image = nil
        
        if Helper.shared.isFileExist(item) {
            cell.downloadButton.setTitle("Delete", for: .normal)
            cell.downloadButton.tag = indexPath2Int(indexPath)
            cell.configure_ed(item)
        } else {
            cell.downloadButton.setTitle("Down", for: .normal)
            cell.downloadButton.tag = indexPath2Int(indexPath)
            cell.configure_able(item)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if tableView.numberOfSections == 2 {
            return section == 0 ? 0 : Const.MusicPlayBarHeight
        }
        return Const.MusicPlayBarHeight
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableView.numberOfSections == 2 {
            return section == 0 ? nil : UIView()
        }
        return UIView()
    }
}

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        searchBar.resignFirstResponder()
        
        showMessagePrompt(NSLocalizedString("Preparing", comment: "Preparing"))
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsScopeBar = true
        searchBar.sizeToFit()
        searchBar.setShowsCancelButton(true, animated: true)
        
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsScopeBar = false
        searchBar.sizeToFit()
        searchBar.setShowsCancelButton(false, animated: false)
        
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchType = SearchType(rawValue: selectedScope) ?? .trackTitle
        print("\(searchType.description)")
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("textDidChange:\(searchText)")
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let txt = searchBar.text else { return }
        search(txt)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        search("") // "" -> search All
    }
    
    private func isNewItem(_ indexPath: IndexPath) -> Bool {
        return newPlaybackItems.hasItems() && indexPath.section == 0
    }
    
    private func search(_ txt: String) {
        showSpinner {
            var tmpPlaybackItems = [PlaybackItem]()
            
            let dataRef = self.ref.child("music/")
                .queryOrdered(byChild: self.searchType.description)
                .queryStarting(atValue: txt)
                .queryEnding(atValue: txt+"\u{f8ff}")
            
            dataRef.observeSingleEvent(of: .value, with: { (snapshot) in
                for item in snapshot.children {
                    guard let value = (item as! DataSnapshot).value else { return }
                    do {
                        let playbackItem = try FirebaseDecoder().decode(PlaybackItem.self, from: value)
                        tmpPlaybackItems.append(playbackItem)
                    } catch let error {
                        self.hideSpinner { }
                        print(error)
                    }
                }
                
                if tmpPlaybackItems != self.playbackItems  {
                    self.playbackItems = tmpPlaybackItems
                    self.playbackItems.sort(by: {$0.downloadCount > $1.downloadCount})
                    self.allPlaybackItems = self.playbackItems
                    self.tableView.reloadData()
                }
                
                self.hideSpinner { }
            })
        }

    }
}

extension Int {
    func dateFromMilliseconds() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self)/1000)
    }
}
