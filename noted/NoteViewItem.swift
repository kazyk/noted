//
//  NoteItemCell.swift
//  noted
//
//  Created by kazuyuki takahashi on 2022/02/13.
//

import AppKit
import Combine
import Carbon

class NoteViewItem: NSCollectionViewItem {
    @IBOutlet private var label: NSTextField!
    @IBOutlet private var textViewPlaceholder: NSView!
    
    private var textView: TextView!
    private var defaultHeight: CGFloat = 0
    private var defaultVerticalMargin: CGFloat = 0
    
    private var cancellable: [AnyCancellable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView = TextView(frame: self.textViewPlaceholder.bounds)
        textView.setAccessibilityIdentifier("NoteViewItemTextView")
        textView.autoresizingMask = [.width] // including .height breaks layout
        textViewPlaceholder.addSubview(textView)
        defaultHeight = textView.frame.height
        defaultVerticalMargin = view.frame.height - textView.frame.height
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellable = []
    }
    
    func update(id: NoteItem.ID) {
        let store = stores().noteItemsStore
        let nc = NotificationCenter.default
        let textView = self.textView!
        let label = self.label!
        let itemState = store.itemState(id: id)
        
        itemState
            .map { state in state.item.text }
            .first()
            .assign(to: \.string, on: textView)
            .store(in: &cancellable)
        
        itemState
            .map { state in
                state.item.isPlaceholder ? "New Item" : "#\(id)"
            }
            .assign(to: \.stringValue, on: label)
            .store(in: &cancellable)
        
        itemState
            .map { state in state.focus }
            .sink { [unowned self] focus in
                if focus {
                    self.view.window?.makeFirstResponder(textView)
                }
            }
            .store(in: &cancellable)
        
        nc.publisher(for: NSText.didChangeNotification, object: textView)
            .sink { [unowned self] _ in
                store.dispatch(.edit(id: id, text: textView.string))
                self.needsLayout()
            }
            .store(in: &cancellable)
        
        textView.deleteKeyDown
            .sink {
                if textView.string == "" {
                    store.dispatch(.remove(id: id))
                }
            }
            .store(in: &cancellable)
        
        textView.shiftEnter
            .sink {
                store.dispatch(.goNext(id: id))
            }
            .store(in: &cancellable)
    }
    
    func itemHeight() -> CGFloat {
        return max(defaultHeight, textView.frame.height) + defaultVerticalMargin
    }
    
    private func needsLayout() {
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
    
    private class TextView: NSTextView, NSTextViewDelegate {
        let deleteKeyDown = PassthroughSubject<(), Never>()
        let shiftEnter = PassthroughSubject<(), Never>()
        
        override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
            super.init(frame: frameRect, textContainer: container)
            delegate = self
        }
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            delegate = self
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        override func keyDown(with event: NSEvent) {
            if event.keyCode == kVK_Delete {
                deleteKeyDown.send()
            }
            
            super.keyDown(with: event)
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            if replacementString == "\n" && NSEvent.modifierFlags.contains(.shift) {
                shiftEnter.send()
                return false
            }

            return true
        }
    }
}

