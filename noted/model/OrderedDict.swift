//
//  OrderedDict.swift
//  noted
//
//  Created by kazuyuki takahashi on 2022/02/16.
//

import Foundation

struct OrderedDict<T >: Codable where T: Codable & Identifiable, T.ID: Codable {
    private var dict: [T.ID: T] = [:]
    private var order: [T.ID] = []
    
    var allIds: [T.ID] {
        order
    }
    
    subscript(_ id: T.ID) -> T? {
        get {
            return dict[id]
        }
        set {
            assert(newValue?.id == id)
            if dict[id] == nil {
                assert(!order.contains(id))
                order.append(id)
            }
            dict[id] = newValue
        }
    }
    
    func previousId(of id: T.ID) -> T.ID? {
        if let idx = order.firstIndex(of: id), idx > 0 {
            return order[idx - 1]
        }
        return nil
    }
    
    func nextId(of id: T.ID) -> T.ID? {
        if let idx = order.firstIndex(of: id), idx < order.count - 1 {
            return order[idx + 1]
        }
        return nil
    }
    
    mutating func append(_ val: T) {
        if dict[val.id] == nil {
            dict[val.id] = val
            order.append(val.id)
        }
    }
    
    mutating func remove(id: T.ID) {
        dict.removeValue(forKey: id)
        if let idx = order.firstIndex(of: id) {
            order.remove(at: idx)
        }
    }
    
}
