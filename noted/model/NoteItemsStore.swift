//
//  NoteItemsStore.swift
//  noted
//
//  Created by kazuyuki takahashi on 2022/02/13.
//

import Foundation
import Combine
import AppKit

struct NoteItem: Identifiable, Codable, Equatable {
    typealias ID = Int
    var id: ID
    var text: String
    var isPlaceholder: Bool
}

struct NoteItemState: Equatable {
    var item: NoteItem
    var focus: Bool
}

class NoteItemsStore: Codable {
    enum Action {
        case edit(id: NoteItem.ID, text: String)
        case remove(id: NoteItem.ID)
        case goNext(id: NoteItem.ID)
    }
    
    @Published private var noteItems = OrderedDict<NoteItem>()
    @Published private var focusId = 1
    private var nextId = 2
    
    private var cancellable: [AnyCancellable] = []
    
    init() {
        noteItems.append(NoteItem(id: 1, text: "", isPlaceholder: true))
    }
    
    func noteItem(id: NoteItem.ID) -> AnyPublisher<NoteItemState, Never> {
        makePublisher {
            $noteItems
                .filter { items in items[id] != nil }
                .combineLatest(focusAt(id: id))
                .map { (items, focus) in
                    NoteItemState(item: items[id]!, focus: focus)
                }
        }
    }
    
    func focusAt(id: NoteItem.ID) -> AnyPublisher<Bool, Never> {
        makePublisher {
            $focusId.map { $0 == id }
        }
    }
    
    func allIds() -> AnyPublisher<[NoteItem.ID], Never> {
        makePublisher {
            $noteItems.map { $0.allIds }
        }
    }
    
    private func makePublisher<P: Publisher>(publisher: () -> P) -> AnyPublisher<P.Output, Never> where P.Output: Equatable, P.Failure == Never {
        publisher()
            .debounce(for: .zero, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func dispatch(_ action: Action) {
        print(action)
        
        switch action {
        case let .edit(id, text):
            noteItems[id]?.text = text
        case let .remove(id):
            guard let item = noteItems[id] else {
                break
            }
            if let prevId = noteItems.previousId(of: id) {
                focusId = prevId
            } else if id == noteItems.allIds[0], noteItems.allIds.count > 1 {
                focusId = noteItems.allIds[1]
            }
            if !item.isPlaceholder {
                noteItems.remove(id: id)
            }
        case let .goNext(id):
            guard let item = noteItems[id], item.text.count > 0 else {
                break
            }
            if item.isPlaceholder {
                noteItems[id]?.isPlaceholder = false
                noteItems.append(NoteItem(id: nextId, text: "", isPlaceholder: true))
                focusId = nextId
                nextId += 1
            } else {
                if let nextId = noteItems.nextId(of: id) {
                    focusId = nextId
                }
            }
        }
    }
    
    // Codable implementation
    
    enum CodingKeys: String, CodingKey {
        case noteItems, focusId, nextId
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        noteItems = try container.decode(OrderedDict<NoteItem>.self, forKey: .noteItems)
        focusId = try container.decode(Int.self, forKey: .focusId)
        nextId = try container.decode(Int.self, forKey: .nextId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(noteItems, forKey: .noteItems)
        try container.encode(focusId, forKey: .focusId)
        try container.encode(nextId, forKey: .nextId)
    }
}
