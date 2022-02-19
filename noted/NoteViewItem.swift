//
//  NoteItemCell.swift
//  noted
//
//  Created by kazuyuki takahashi on 2022/02/13.
//

import AppKit
import Combine
import Carbon

private let inset: CGFloat = 8

class NoteViewItem: NSCollectionViewItem, NSTextViewDelegate {
    private var textView: TextView!
    private var defaultHeight: CGFloat = 0
    
    private var id: NoteItem.ID?
    private var cancellable: [AnyCancellable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView = TextView(frame: self.view.bounds.insetBy(dx: inset, dy: inset))
        textView.setAccessibilityIdentifier("NoteViewItemTextView")
        textView.autoresizingMask = [.width] // including .height breaks layout
        view.addSubview(textView)
        textView.delegate = self
        defaultHeight = textView.frame.height
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        id = nil
        cancellable = []
        textView.deleteKeyListener = nil
    }
    
    func update(noteItem: NoteItem, shouldFocus: AnyPublisher<Bool, Never>) {
        let nc = NotificationCenter.default
        let textView = self.textView!
        id = noteItem.id
        textView.string = noteItem.text
        
        nc.publisher(for: NSText.didChangeNotification, object: textView)
            .sink { _ in
                stores().noteItemsStore.dispatch(.edit(id: noteItem.id, text: textView.string))
            }
            .store(in: &cancellable)
        
        shouldFocus
            .sink { [unowned self] focus in
                if focus {
                    self.view.window?.makeFirstResponder(textView)
                }
            }
            .store(in: &cancellable)
        
        textView.deleteKeyListener = { textView in
            if textView.string == "" {
                stores().noteItemsStore.dispatch(.remove(id: noteItem.id))
            }
        }
    }
    
    func itemHeight() -> CGFloat {
        return max(defaultHeight, textView.frame.height) + inset * 2
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        if replacementString == "\n" && NSEvent.modifierFlags.contains(.shift) {
            stores().noteItemsStore.dispatch(.goNext(id: id!))
            return false
        }

        return true
    }
    
    func textDidChange(_ notification: Notification) {
        if let collectionView = self.collectionView {
            let context = NSCollectionViewFlowLayoutInvalidationContext()
            let indexPath = collectionView.indexPath(for: self)!
            context.invalidateItems(at: Set([indexPath]))
            collectionView.collectionViewLayout?.invalidateLayout(with: context)
        }
    }
    
    override func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        // somehow origin is not kept after layout
        textView.frame.origin.y = inset
    }
    
    private class TextView: NSTextView {
        var deleteKeyListener: ((TextView) -> Void)?
        
        override func keyDown(with event: NSEvent) {
            if event.keyCode == kVK_Delete {
               deleteKeyListener?(self)
            }
            
            super.keyDown(with: event)
        }
    }
}

