//
//  Item.swift
//  App-search
//
//  Created by k zhukovskaya on 20.04.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
