//
//  Helper.swift
//  HiroPlayer
//
//  Created by seunghwan.yoo on 2019/09/18.
//  Copyright © 2019 Yoo. All rights reserved.
//

import Foundation
import Firebase
import AVFoundation
import CodableFirebase

class Helper {
    
    static let shared = Helper()
    
    let ref = Database.database().reference()
    
    func setDownloadCount(_ value: NSDictionary?, _ isIncrease: Bool, _ uid: String) -> Int {
        guard let value = value else { return 0 }
        var downloadCnt = value["downloadCount"] as? Int ?? 0
        downloadCnt = isIncrease ? downloadCnt+1 : downloadCnt-1
        self.ref.child("music/"+uid).updateChildValues(["downloadCount":downloadCnt])
        return downloadCnt
    }
    
    func getItem(_ item: PlaybackItem, result:@escaping(PlaybackItem?) -> Void) {
        self.ref.child("music/"+item.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let value = snapshot.value as? NSDictionary else { return }
            do {
                let playItem = try FirebaseDecoder().decode(PlaybackItem.self, from: value)
                result(playItem)
            } catch let error {
                print(error)
                result(nil)
            }
        })
    }
    
    func getAllItems(result:@escaping([PlaybackItem]) -> Void) {
        self.ref.child("music/").observeSingleEvent(of: .value, with: { (snapshot) in
            guard let value = snapshot.value as? NSDictionary else { return }
            var playbackItems = [PlaybackItem]()
            for key in value.allKeys {
                guard let item = value[key] else { return }
                do {
                    let playItem = try FirebaseDecoder().decode(PlaybackItem.self, from: item)
                    playbackItems.append(playItem)
                } catch let error {
                    print(error)
                    result([])
                }
            }
            result(playbackItems)
        })
    }

    
    // MARK: - delete
    func deleteAlbumSong(_ path: String) {
        let localPath = "\(Const.Paths.documentsPath)/\(path)"
        do {
            try FileManager.default.removeItem(atPath: localPath)
            try FileManager.default.removeItem(atPath: "\(localPath).png")
            LibraryManager.shared.removeAlbumLibrary(path)
            LibraryManager.shared.removeAlbumFavorite(path)
        } catch {
            print("error")
        }
    }
    
    func deleteAlbumSong(_ playItem: PlaybackItem) {
        self.deleteAlbumSong(playItem.trackUrl)
    }
    
    func deleteMusicSong(_ playItem: PlaybackItem) {
        let localUrlStr = "\(Const.Paths.documentsPath)/music/\(playItem.artistName)/\(playItem.trackTitle)"
        do {
            let uid = playItem.uid
            try FileManager.default.removeItem(atPath: localUrlStr)
            self.ref.child("music/"+uid).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                _ = self.setDownloadCount(value, false, uid)
                LibraryManager.shared.removeLibrary(playItem)
                LibraryManager.shared.removeFavorite(playItem)
            }) { (error) in
                print(error.localizedDescription)
            }
        } catch {
            print("error")
        }
    }

    // MARK: - isFileExist
    func isFileExist(_ path: String) -> Bool {
        let localPath = Const.Paths.documentsPath + "/" + path
        print("localPath:\(localPath)")
        
        return FileManager.default.fileExists(atPath: localPath)
    }
    
    func isFileExist(_ playItem:PlaybackItem) -> Bool {
        return self.isFileExist(playItem.trackUrl)
    }
    
    // MARK: - common func
    func playInYoutube(_ youtubeId: String) {
        if let youtubeURL = URL(string: "youtube://\(youtubeId)"),
            UIApplication.shared.canOpenURL(youtubeURL) {
            // redirect to app
            UIApplication.shared.open(youtubeURL, options: [:], completionHandler: nil)
        } else if let youtubeURL = URL(string: "https://www.youtube.com/watch?v=\(youtubeId)") {
            // redirect through safari
            UIApplication.shared.open(youtubeURL, options: [:], completionHandler: nil)
        }
    }
    
}
