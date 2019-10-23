//
//  LibraryViewController.swift
//  HiroPlayer
//
//  Created by Yoo on 2018/11/14.
//  Copyright © 2018年 nakazato. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

private let margin: CGFloat = 10
private let viewInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
private let imageEx = ["jpg","jpeg","png","gif","tiff"]
private let audioEx = ["m4a","mp3","wav","caf","mp4"]

class LibraryViewController: UIViewController {

    @IBOutlet weak var bottomConst: NSLayoutConstraint!
    
    fileprivate var longPressGesture: UILongPressGestureRecognizer!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noPlaylistLabel: UILabel!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var trashButton: UIBarButtonItem!
    
    var playbackItems = [PlaybackItem]()

    private var editMode = false
    private let ref = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Library", comment: "Library")
        
        let longPressGesture = UILongPressGestureRecognizer(target: self,
                                                            action: #selector(self.handleLongGesture(_:)))
        collectionView.addGestureRecognizer(longPressGesture)
        
        syncLibraryFavoriteList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getPlaybackItemList() { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    private func syncLibraryFavoriteList() {
        LibraryManager.shared.checkLocalItems()
    }
    
    private func getPlaybackItemList(completion:@escaping() -> Void) {
        playbackItems = LibraryManager.shared.getPlaybackItems()
        completion()
    }
        
    private func getListFromLocalFolder(_ urlStr: String) -> [String]? {
        return try? FileManager.default.contentsOfDirectory(atPath: urlStr)
    }
            
    @IBAction func favoriteAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            LibraryManager.shared.addFavorite(playbackItems[sender.tag])
        } else {
            LibraryManager.shared.removeFavorite(playbackItems[sender.tag])
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            sender.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        }, completion: { (finish) in
            UIView.animate(withDuration: 0.3, animations: {
                sender.transform = CGAffineTransform.identity
            })
        })
    }
    
    
    @IBAction func editAction(_ sender: UIBarButtonItem) {
        editMode = !editMode
        collectionView.allowsMultipleSelection = editMode
        navigationItem.rightBarButtonItem?.isEnabled = !editMode
        setTabBarHidden(editMode)
        
        //playbar 表示してる時は非表示へ
        if let tabbarController = self.tabBarController as? TabBarController {
            tabbarController.playBar.close()
        }        
        
        if editMode {
            sender.title = "Cancel"
        } else {            
            sender.title = "Edit"
            
            //Edit select reset
            collectionView.indexPathsForSelectedItems?
                .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
        }
    }
    
    @IBAction func favorateAction(_ sender: UIBarButtonItem) {
        if sender.image == UIImage(named: "heart") {
            sender.image = UIImage(named: "heart_")
            playbackItems = LibraryManager.shared.getLibrary()
            LibraryManager.shared.viewType = .Library
        } else {
            sender.image = UIImage(named: "heart")
            playbackItems = LibraryManager.shared.getFavorite()
            LibraryManager.shared.viewType = .Favorite
        }
        collectionView.reloadData()
    }
    
    @IBAction func deleteAciton(_ sender: UIBarButtonItem) {
        guard let indexPaths = collectionView.indexPathsForSelectedItems else { return }
        if indexPaths.count > 0 {
            let message = "\(indexPaths.count)項目を削除します。\nよろしいですか？"
            let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
                self.delete(indexPaths)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.showMessagePrompt("削除する曲を選択してください")
        }
        
    }
    
    @objc func handleLongGesture(_ gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    private func delete(_ indexPaths: [IndexPath]) {
        showSpinner {
            indexPaths.forEach { idx in
                let playItem: PlaybackItem = self.playbackItems[idx.row]
                self.playbackItems.remove(playItem)
                if playItem.uid == "" { // uid がないと album
                    Helper.shared.deleteAlbumSong(playItem)
                } else {
                    Helper.shared.deleteMusicSong(playItem)
                }
            }
            
            self.hideSpinner {
                self.collectionView.reloadData()
                self.showMessagePrompt("削除しました。")
            }
        }
    }
}

extension LibraryViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if playbackItems.count > 0 {
            noPlaylistLabel.alpha = 0.0
        } else {
            noPlaylistLabel.alpha = 1.0
        }
        return playbackItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : LibraryCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MusicCell", for: indexPath as IndexPath) as! LibraryCell
        
        let item = playbackItems[indexPath.row]
        cell.configure(item)
        cell.favoriteButton.tag = indexPath.row
        cell.isSelected = false
        cell.setShadow()

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let tmp = playbackItems.remove(at: sourceIndexPath.row)
        playbackItems.insert(tmp, at: destinationIndexPath.item)
        
        LibraryManager.shared.setPlaybackItem(playbackItems)
    }
}

extension LibraryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if editMode {

        } else {
            if let tabbarController = self.tabBarController as? TabBarController {
                tabbarController.presentPlayerView(playbackItems[indexPath.row])
                //selected から元に戻す
                collectionView.reloadItems(at: [indexPath])
            }
        }
    }
}

extension LibraryViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.view.bounds.width-(margin*3)
        return CGSize(width: width/2, height: width/2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return viewInset
    }
}
