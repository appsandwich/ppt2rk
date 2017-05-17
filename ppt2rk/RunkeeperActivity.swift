//
//  RunkeeperActivity.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 17/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class RunkeeperActivity {
    
    public var id: Int
    public var timestamp: Date
    public var distance: String
    public var duration: String
    public var day: String
    public var convertedFromGPXString: String?
    
    init(id: Int, timestamp: Date, distance: String, duration: String, day: String) {
        self.id = id
        self.timestamp = timestamp
        self.distance = distance
        self.duration = duration
        self.day = day
    }
}
