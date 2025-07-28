//
//  Item.swift
//  RallyProMac
//
//  Created by Matthew Chew on 28/7/25.
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
