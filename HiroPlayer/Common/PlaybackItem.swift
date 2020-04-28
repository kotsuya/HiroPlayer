//
//  PlaybackItem.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/15.
//  Copyright © 2018年 Yoo. All rights reserved.
//

import Foundation
/*
uid: uid,
artistName: $('#artist_name').val(),
trackTitle: $('#track_title').val(),
description: $('#description').val(),
release: $('#release:checked').val(),
addBy: user.email,
trackUrl: '',
artworkUrl: '',
artworkWebUrl: '',
downloadCount: 0,
createdAt: '',
updatedAt: ''
 
 -LUEHFqamv2bDY2wK1Xt:
 addBy: "kotsuya@naver.com"
 artistName: "TWICE"
 artworkUrl: "music/TWICE/TT/tt-.jpg"
 artworkWebUrl: "https://firebasestorage.googleapis.com/v0/b/hiroplayer-a0126.appspot.com/o/music%2FTWICE%2FTT%2Ftt-.jpg?alt=media&token=dbe7c3f4-8a43-43e4-9b86-387243b33f04"
 createdAt: 1545370936467
 description: "madsky pick"
 downloadCount: 0
 release: "public"
 trackTitle: "TT"
 trackUrl: "music/TWICE/TT/tt.m4a"
 uid: "-LUEHFqamv2bDY2wK1Xt"
 
*/

public struct PlaybackItem: Codable {
    let uid: String
    let artistName: String
    let trackTitle: String
    let description: String
    let release: String //public private
    let addBy: String
    let trackUrl: String
    let artworkUrl: String
    let artworkWebUrl: String
    var downloadCount: Int
    var createdAt: Date?
    //let updatedAt: String
    
    let youtubeId: String?
    let lyrics: String?
}

extension PlaybackItem: Equatable {}
public func ==(lhs: PlaybackItem, rhs: PlaybackItem) -> Bool {
    return lhs.artistName == rhs.artistName && lhs.trackTitle == rhs.trackTitle
}
