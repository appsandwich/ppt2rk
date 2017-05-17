//
//  PolarWorkout.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 12/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class PolarWorkout {
    
    static let idsKey = "com.appsandwich.ppt2rk.defaults-key-workouts"
    
    public var id: String
    public var timestamp: String
    public var distance: String
    public var duration: String
    public var runkeeperMonth, runkeeperDay: String?
    
    init(id: String, timestamp: String, distance: String, duration: String, runkeeperMonth: String?, runkeeperDay: String?) {
        
        self.id = id
        self.timestamp = timestamp
        self.distance = distance
        self.duration = duration
        self.runkeeperMonth = runkeeperMonth
        self.runkeeperDay = runkeeperDay
    }
    
    public func markAsDownloaded() {
        
        var ids = PolarWorkout.downloadedWorkoutIDs()
        
        if ids == nil {
            ids = []
        }
        else {
            guard ids?.index(of: self.id) == nil else {
                return
            }
        }
        
        
        var mutableIDs: [String] = []
        
        mutableIDs.append(contentsOf: ids!)
        mutableIDs.append(self.id)
        
        UserDefaults.standard.set(mutableIDs, forKey: PolarWorkout.idsKey)
        UserDefaults.standard.synchronize()
    }
    
    public class func downloadedWorkoutIDs() -> [String]? {
        
        UserDefaults.standard.synchronize()
        
        guard let ids = UserDefaults.standard.array(forKey: self.idsKey) as? [String]? else {
            return nil
        }
        
        return ids
    }
    
    public class func resetDownloadedWorkoutIDs() {
        UserDefaults.standard.removeObject(forKey: self.idsKey)
        UserDefaults.standard.synchronize()
    }
}

extension PolarWorkout: CustomStringConvertible {
    var description: String {
        return "****************\nPolarWorkout\nid: \(self.id)\ntimestamp: \(self.timestamp)\ndistance: \(self.distance)\nduration: \(self.duration)\n****************"
    }
}

extension PolarWorkout: Equatable {}

// MARK: Equatable

func ==(lhs: PolarWorkout, rhs: PolarWorkout) -> Bool {
    return lhs.id == rhs.id
}
