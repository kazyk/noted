//
//  Stores.swift
//  noted
//
//  Created by kazuyuki takahashi on 2022/02/13.
//

import Foundation
import AppKit

struct Stores: Codable {
    var noteItemsStore: NoteItemsStore
    
    func save() throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: storeFileUrl, options: [.atomic])
    }
}

private let storeFileUrl: URL = {
    let fileName = ProcessInfo.processInfo.environment["storeFileName"] ?? "Store.json"
    do {
        let dir = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true)
        return dir.appendingPathComponent(fileName)
    } catch let e {
        NSAlert(error: e).runModal()
        exit(-1)
    }
}()

private let shared: Stores = {
    if FileManager.default.fileExists(atPath: storeFileUrl.path) {
        do {
            let data = try Data(contentsOf: storeFileUrl)
            let stores = try JSONDecoder().decode(Stores.self, from: data)
            return stores
        } catch let e {
            print("load failed", e.localizedDescription)
        }
    }
    
    return Stores(noteItemsStore: NoteItemsStore())
}()

func stores() -> Stores {
    return shared
}
