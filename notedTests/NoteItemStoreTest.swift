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
        let item = store.noteItem(id: ids[0])
        XCTAssertNotNil(item)
        
        XCTAssertEqual(item?.isPlaceholder, true)
        XCTAssertEqual(item?.text, "")
    }
    
    func testInitialFocusId() throws {
        let store = NoteItemsStore()
        
        let ids = getFirst(store.allIds())
        let focus = getFirst(store.shouldFocusAt(id: ids[0]))
        XCTAssertTrue(focus)
    }
    
    func testEditItem() throws {
        let store = NoteItemsStore()
        
        let ids = getFirst(store.allIds())
        store.dispatch(.edit(id: ids[0], text: "test text"))
        let item = store.noteItem(id: ids[0])
        XCTAssertEqual(item?.text, "test text")
    }
    
    func testCreateNewItem() {
        let store = NoteItemsStore()
        
        var ids = getFirst(store.allIds())
        store.dispatch(.edit(id: ids[0], text: "test"))
        store.dispatch(.goNext(id: ids[0]))

        ids = getFirst(store.allIds())
        XCTAssertEqual(ids.count, 2)
        
        let item = store.noteItem(id: ids[1])
        XCTAssertEqual(item?.text, "")
        XCTAssertEqual(item?.isPlaceholder, true)
        
        let focus = getFirst(store.shouldFocusAt(id: ids[1]))
        XCTAssertTrue(focus)
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
        
        let item = store.noteItem(id: newIds[0])
        XCTAssertEqual(item?.isPlaceholder, true)
        
        let focus = getFirst(store.shouldFocusAt(id: newIds[0]))
        XCTAssertTrue(focus)
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


