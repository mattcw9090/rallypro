//
//  Item.swift
//  RallyPro
//
//  Created by Matthew Chew on 19/1/25.
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
