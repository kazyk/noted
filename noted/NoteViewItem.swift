//
//  NoteItemCell.swift
//  noted
//
//  Created by kazuyuki takahashi on 2022/02/13.
//

import AppKit
import Combine
import Carbon

class NoteViewItem: NSCollectionViewItem, NSTextViewDelegate {
    @IBOutlet private var label: NSTextField!
    @IBOutlet private var textViewPlaceholder: NSView!
    
    private var textView: TextView!
    private var defaultHeight: CGFloat = 0
    private var defaultVerticalMargin: CGFloat = 0
    private var top: CGFloat = 0
    private var bottom: CGFloat = 0
    
    private var id: NoteItem.ID?
    private var cancellable: [AnyCancellable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView = TextView(frame: self.textViewPlaceholder.bounds)
        textView.setAccessibilityIdentifier("NoteViewItemTextView")
        textView.autoresizingMask = [.width] // including .height breaks layout
        textViewPlaceholder.addSubview(textView)
        textView.delegate = self
        defaultHeight = textView.frame.height
        defaultVerticalMargin = view.frame.height - textView.frame.height
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        id = nil
        cancellable = []
    }
    
    func update(id: NoteItem.ID, noteItem: AnyPublisher<NoteItemState, Never>) {
        let nc = NotificationCenter.default
        let textView = self.textView!
        let label = self.label!
        self.id = id
        
        noteItem
            .map { state in state.item.text }
            .first()
            .sink { textView.string = $0 }
            .store(in: &cancellable)
        
        noteItem
            .sink { state in
                label.stringValue = state.item.isPlaceholder ? "New Item" : "#\(id)"
            }
            .store(in: &cancellable)
        
        noteItem
            .map { state in state.focus }
            .sink { [unowned self] focus in
                if focus {
                    self.view.window?.makeFirstResponder(textView)
                }
            }
            .store(in: &cancellable)
        
        nc.publisher(for: NSText.didChangeNotification, object: textView)
            .sink { _ in
                stores().noteItemsStore.dispatch(.edit(id: id, text: textView.string))
            }
            .store(in: &cancellable)
        
        textView.deleteKeyDown
            .sink {
                if textView.string == "" {
                    stores().noteItemsStore.dispatch(.remove(id: id))
                }
            }
            .store(in: &cancellable)
    }
    
    func itemHeight() -> CGFloat {
        return max(defaultHeight, textView.frame.height) + defaultVerticalMargin
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
        textView.frame.origin.y = 0
    }
    
    private class TextView: NSTextView {
        let deleteKeyDown = PassthroughSubject<(), Never>()
        
        override func keyDown(with event: NSEvent) {
            if event.keyCode == kVK_Delete {
                deleteKeyDown.send()
            }
            
            super.keyDown(with: event)
        }
    }
}

