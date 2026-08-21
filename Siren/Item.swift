//
//  Item.swift
//  Siren
//
//  Created by Vik Kalahasthi on 8/21/26.
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
