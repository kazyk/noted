//
//  NoteItemStoreTest.swift
//  notedTests
//
//  Created by kazuyuki takahashi on 2022/02/19.
//

import XCTest
import Combine
@testable import noted

class NoteItemStoreTest: XCTestCase {
    
    var cancellable: [AnyCancellable] = []
    
    override func setUpWithError() throws {
        cancellable = []
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitialItems() throws {
        let store = NoteItemsStore()
        
        let ids = getFirst(store.allIds())
        XCTAssertEqual(ids.count, 1)
        let state = getFirst(store.itemState(id: ids[0]))
        
        XCTAssertEqual(state.item.isPlaceholder, true)
        XCTAssertEqual(state.item.text, "")
    }
    
    func testInitialFocusId() throws {
        let store = NoteItemsStore()
        
        let ids = getFirst(store.allIds())
        let state = getFirst(store.itemState(id: ids[0]))
        XCTAssertTrue(state.focus)
    }
    
    func testEditItem() throws {
        let store = NoteItemsStore()
        
        let ids = getFirst(store.allIds())
        store.dispatch(.edit(id: ids[0], text: "test text"))
        let state = getFirst(store.itemState(id: ids[0]))
        XCTAssertEqual(state.item.text, "test text")
    }
    
    func testCreateNewItem() {
        let store = NoteItemsStore()
        
        var ids = getFirst(store.allIds())
        store.dispatch(.edit(id: ids[0], text: "test"))
        store.dispatch(.goNext(id: ids[0]))

        ids = getFirst(store.allIds())
        XCTAssertEqual(ids.count, 2)
        
        let state = getFirst(store.itemState(id: ids[1]))
        XCTAssertEqual(state.item.text, "")
        XCTAssertEqual(state.item.isPlaceholder, true)
        XCTAssertTrue(state.focus)
    }
    
    func testRemoveItem() {
        let store = NoteItemsStore()
        
        var ids = getFirst(store.allIds())
        store.dispatch(.edit(id: ids[0], text: "test"))
        store.dispatch(.goNext(id: ids[0]))
        ids = getFirst(store.allIds())
        
        XCTAssertEqual(ids.count, 2)
        store.dispatch(.remove(id: ids[0]))
        
        let newIds = getFirst(store.allIds())
        XCTAssertEqual(newIds.count, 1)
        XCTAssertEqual(newIds[0], ids[1])
        
        let state = getFirst(store.itemState(id: newIds[0]))
        XCTAssertEqual(state.item.isPlaceholder, true)
        XCTAssertTrue(state.focus)
    }
    
    private func getFirst<P: Publisher>(_ publisher: P) -> P.Output {
        let exp = expectation(description: "")
        var value: P.Output!
        publisher
            .catch { _ in Empty() }
            .first()
            .sink {
                value = $0
                exp.fulfill()
            }
            .store(in: &cancellable)
        wait(for: [exp], timeout: 1)
        return value
    }
}


