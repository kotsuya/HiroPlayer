//
//  LibraryManager.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/12/21.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import Foundation

enum ViewType : String {
    case Library
    case Favorite
}

class LibraryManager {
    
    static let shared = LibraryManager()
    
    var viewType: ViewType = .Library
    
    public func setLibrary(_ value: [PlaybackItem]) {
        let userDefaults = UserDefaults.standard
        let data = value.map { try? JSONEncoder().encode($0) }
        userDefaults.set(data, forKey: "libraryList")
        userDefaults.synchronize()
    }
    
    public func getLibrary() -> [PlaybackItem] {
        let userDefaults = UserDefaults.standard
        guard let encodedData = userDefaults.array(forKey: "libraryList") as? [Data] else {
            return []
        }
        return encodedData.map { try! JSONDecoder().decode(PlaybackItem.self, from: $0) }
    }
    
    public func addLibrary(_ value: PlaybackItem) {
        let userDefaults = UserDefaults.standard
        var list = getLibrary()
        list.append(value)
        setLibrary(list)
        userDefaults.synchronize()
    }
    
    public func removeLibrary(_ value: PlaybackItem) {
        let userDefaults = UserDefaults.standard
        var list = getLibrary()
        list.remove(value)
        setLibrary(list)
        userDefaults.synchronize()
    }
    
    public func setFavorite(_ value: [PlaybackItem]) {
        let userDefaults = UserDefaults.standard
        let data = value.map { try? JSONEncoder().encode($0) }
        userDefaults.set(data, forKey: "favoriteList")
        userDefaults.synchronize()
    }
    
    public func getFavorite() -> [PlaybackItem] {
        let userDefaults = UserDefaults.standard
        guard let encodedData = userDefaults.array(forKey: "favoriteList") as? [Data] else {
            return []
        }
        return encodedData.map { try! JSONDecoder().decode(PlaybackItem.self, from: $0) }
    }
    
    public func addFavorite(_ value: PlaybackItem) {
        let userDefaults = UserDefaults.standard
        var list = getFavorite()
        list.append(value)
        setFavorite(list)
        userDefaults.synchronize()
    }
    
    public func removeFavorite(_ value: PlaybackItem) {
        let userDefaults = UserDefaults.standard
        var list = getFavorite()
        list.remove(value)
        setFavorite(list)
        userDefaults.synchronize()
    }
    
    public func isFavorite(_ value: PlaybackItem) -> Bool {
        let list = getFavorite()
        return list.contains(value)
    }
    
    public func getPlaybackItems() -> [PlaybackItem] {
        let userDefaults = UserDefaults.standard
        if viewType == .Library {
            guard let encodedData = userDefaults.array(forKey: "libraryList") as? [Data] else {
                return []
            }
            return encodedData.map { try! JSONDecoder().decode(PlaybackItem.self, from: $0) }
        } else {
            guard let encodedData = userDefaults.array(forKey: "favoriteList") as? [Data] else {
                return []
            }
            return encodedData.map { try! JSONDecoder().decode(PlaybackItem.self, from: $0) }
        }
    }
    
    public func setPlaybackItem(_ value: [PlaybackItem]) {
        let userDefaults = UserDefaults.standard
        if viewType == .Library {
            let data = value.map { try? JSONEncoder().encode($0) }
            userDefaults.set(data, forKey: "libraryList")
        } else {
            let data = value.map { try? JSONEncoder().encode($0) }
            userDefaults.set(data, forKey: "favoriteList")
        }
        userDefaults.synchronize()
    }
    
    public func checkLocalItems() {        
        let library = getLibrary().filter { Helper.shared.isFileExist($0) }
        if library != getLibrary()  { setLibrary(library) }
        
        let favorite = getFavorite().filter { Helper.shared.isFileExist($0) }
        if favorite != getFavorite()  { setFavorite(favorite) }
    }
    
    public func removeAlbumLibrary(_ value: String) {
        let userDefaults = UserDefaults.standard
        let list = getLibrary()
        setLibrary(list.filter { !$0.trackUrl.contains(value) })
        userDefaults.synchronize()
    }
    
    public func removeAlbumFavorite(_ value: String) {
        let userDefaults = UserDefaults.standard
        let list = getFavorite()
        setFavorite(list.filter { !$0.trackUrl.contains(value) })
        userDefaults.synchronize()
    }
}
