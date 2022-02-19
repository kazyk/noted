//
//  ViewController.swift
//  noted
//
//  Created by kazuyuki takahashi on 2022/02/13.
//

import Cocoa
import Combine

class NoteItemsViewController: NSViewController, NSCollectionViewDelegateFlowLayout {
    
    @IBOutlet private var collectionView: NSCollectionView!
    
    private var cancellable: [AnyCancellable] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let store = stores().noteItemsStore
        
        collectionView.delegate = self
        collectionView.register(NSNib(nibNamed: "NoteViewItem", bundle: nil), forItemWithIdentifier: .init("cell"))
        
        let dataSource = NSCollectionViewDiffableDataSource<String, NoteItem.ID>(
            collectionView: collectionView,
            itemProvider: { collectionView, indexPath, identifier in
                let item = collectionView.makeItem(withIdentifier: .init("cell"), for: indexPath) as! NoteViewItem
                item.update(noteItem: store.noteItem(id: identifier)!, shouldFocus: store.shouldFocusAt(id: identifier))
                return item
            })
        collectionView.dataSource = dataSource
        
        store.allIds()
            .map { ids in
                var snapshot = NSDiffableDataSourceSnapshot<String, NoteItem.ID>()
                snapshot.appendSections([""])
                snapshot.appendItems(ids)
                return snapshot
            }
            .sink { dataSource.apply($0) }
            .store(in: &cancellable)
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        
        // update item width
        collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        guard let item = collectionView.item(at: indexPath) as? NoteViewItem else {
            return CGSize(width: collectionView.frame.width, height: 52)
        }
        return CGSize(width: collectionView.frame.width, height: item.itemHeight())
    }
}
