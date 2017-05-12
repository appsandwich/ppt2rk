//
//  PolarWorkout.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 12/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class PolarWorkout {
    
    public var id: String
    public var timestamp: String
    
    init(id: String, timestamp: String) {
        self.id = id
        self.timestamp = timestamp
    }
}

extension PolarWorkout: Equatable {}

// MARK: Equatable

func ==(lhs: PolarWorkout, rhs: PolarWorkout) -> Bool {
    return lhs.id == rhs.id
}
