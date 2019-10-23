//
//  AlbumViewController.swift
//  HiroPlayer
//
//  Created by seunghwan.yoo on 2019/09/13.
//  Copyright © 2019 nakazato. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import AVFoundation
import MediaPlayer

enum AlbumViewType: String {
    case folder
    case file
}

class AlbumViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!{
        didSet {
            tableView.tableFooterView = UIView(frame: CGRect.zero)
        }
    }
    
    let ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    var refreshControl: UIRefreshControl!
    
    private var myItems = [String]()
    
    var dataPath = "album"
    var albumViewType: AlbumViewType = .folder
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Album", comment: "Album")
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        setTableViewItems()
    }
    
    @IBAction func downloadAction(_ sender: UIButton) {
        guard let btnTitle = sender.currentTitle else { return }
        
        var title = "Purchase"
        var message = NSLocalizedString("Purchase_Confirm_Message", comment: "Message")
        if btnTitle == "Del" {
            title = "Delete"
            message = "\(myItems[sender.tag]) Delete?"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: title, style: .default) { (UIAlertAction) in
            if btnTitle == "Del" {
                let path = "\(self.dataPath)/\(self.myItems[sender.tag])"
                Helper.shared.deleteAlbumSong(path)
                self.tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .automatic)
            } else {
                self.download(sender.tag)
            }
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func download(_ tag: Int) {
        let storage = Storage.storage()
        let storageReference = storage.reference().child(dataPath).child("\(myItems[tag])")
        
        let path = "\(dataPath)/\(myItems[tag])"
        let localURL = URL(fileURLWithPath: Const.Paths.documentsPath+"/\(path)")
        showSpinner {
            let downloadTask = storageReference.write(toFile: localURL)
            downloadTask.observe(.progress) { snapshot in
                // Download reported progress
                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                    / Double(snapshot.progress!.totalUnitCount)
                print("percentComplete:\(percentComplete)")
            }
            
            downloadTask.observe(.success) { snapshot in
                self.setPlaybackItem(path)
                
                self.hideSpinner {
                    self.showMessagePrompt("Download Success!")
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @objc private func downloadAll(_ sender: UIBarButtonItem) {
        let storage = Storage.storage()
        let storageReference = storage.reference().child(dataPath)
        showSpinner {
            storageReference.listAll { (result, error) in
                if let error = error {
                    print("error:\(error)")
                    self.hideSpinner { }
                }
                var count = 0
                for item in result.items {
                    if let fileName = item.fullPath.components(separatedBy: "/").last {
                        let path = "\(self.dataPath)/\(fileName)"
                        let localURL = URL(fileURLWithPath: Const.Paths.documentsPath+"/\(path)")
                        
                        // check File isExist
                        if Helper.shared.isFileExist(path) {
                            count = count + 1
                            continue
                        }
                        
                        let ref = storage.reference().child("\(path)")
                        let downloadTask = ref.write(toFile: localURL)
                        downloadTask.observe(.progress) { snapshot in
                            // Download reported progress
                            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                                / Double(snapshot.progress!.totalUnitCount)
                            print("percentComplete:\(percentComplete)")
                        }
                        
                        downloadTask.observe(.success) { snapshot in
                            count = count + 1
                            self.setPlaybackItem(path)
                            if let alert = self.presentedViewController, alert is UIAlertController {
                                (alert as! UIAlertController).message = "Please Wait...[\(count)/\(result.items.count)]\n\n\n"
                            }
                            
                            if result.items.count == count {
                                self.hideSpinner {
                                    self.showMessagePrompt("Download Success!")
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setPlaybackItem(_ path: String) {
        //mp3 file metadata から情報を取る
        let localURL = URL(fileURLWithPath: Const.Paths.documentsPath+"/\(path)")
        let playerItem = AVPlayerItem(url: localURL)
        let metadataList = playerItem.asset.metadata
        
        var title = ""
        var artist = ""
        for item in metadataList {
            guard let key = item.commonKey?.rawValue, let value = item.value else{
                continue
            }
            
            switch key {
            case "title" : title = value as! String
            case "artist": artist = value as! String
            case "artwork" where value is Data :
                saveImage("\(path).png", data: value as! Data)
            default:
                continue
            }
        }
        
        let item = PlaybackItem(uid: "", artistName: artist, trackTitle: title, description: "Album", release: "public", addBy: "", trackUrl: "\(path)", artworkUrl: "\(path).png", artworkWebUrl: "", downloadCount: 0, createdAt: Date())

        LibraryManager.shared.addLibrary(item)
    }
    
    private func setTableViewItems() {
        showSpinner {
            self.getPlaybackItems(completion: { success in
                self.hideSpinner {
                    if self.albumViewType == .file {
                        let downloadAllBtn = UIBarButtonItem(title: "Download All", style: .plain, target: self, action: #selector(self.downloadAll(_:)))
                        self.navigationItem.rightBarButtonItem = downloadAllBtn
                    }
                }
            })
        }
    }
    
    private func getPlaybackItems(completion:@escaping (Bool) -> Void) {
        myItems.removeAll()
        
        let storage = Storage.storage()
        let storageReference = storage.reference().child(dataPath)
        storageReference.listAll { [weak self] (result, error) in
            if let error = error {
                print("error:\(error)")
                completion(false)
            }
            
            if result.prefixes.count > 0 {
                for prefix in result.prefixes {
                    self?.myItems.append(prefix.name)
                    self?.albumViewType = .folder
                }
            } else if result.items.count > 0 {
                for item in result.items {
                    self?.myItems.append(item.name)
                    self?.albumViewType = .file
                }
            }
            
            self?.tableView.reloadData()
            completion(true)
        }
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
        getPlaybackItems(completion: { _ in
            self.refreshControl.endRefreshing()
        })
    }
    
    private func saveImage(_ fileName: String, data: Data) {
        let localURL = URL(fileURLWithPath: Const.Paths.documentsPath+"/\(fileName)")
        if FileManager.default.fileExists(atPath: localURL.path) { return }

        do {
            try data.write(to: localURL)
        } catch let error {
            print("error saving file with error", error)
        }        
    }
}
    
extension AlbumViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell", for: indexPath) as! AlbumCell
        cell.titleLabel.text = "\(myItems[indexPath.row])"
        
        if albumViewType == .folder {
            cell.folderImageView.image = UIImage(named: "folder")
        } else {
            cell.folderImageView.image = UIImage(named: "file")
        }
        
        cell.downloadButton.isHidden = albumViewType == .folder
        
        if !cell.downloadButton.isHidden {
            let path = "\(dataPath)/" + myItems[indexPath.row]
            if Helper.shared.isFileExist(path) {
                cell.downloadButton.setTitle("Del", for: .normal)
            } else {
                cell.downloadButton.setTitle("Down", for: .normal)
            }
            cell.downloadButton.tag = indexPath.row
        }
        return cell
    }
}

extension AlbumViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        if albumViewType == .folder {
            let vc = storyboard?.instantiateViewController(withIdentifier: "AlbumViewController") as! AlbumViewController
            vc.dataPath = dataPath + "/\(myItems[indexPath.row])"
            self.navigationController?.pushViewController(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

