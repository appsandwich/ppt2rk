//
//  RunkeeperActivityUploadQueue.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 22/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class RunkeeperActivityUploadQueue {
    
    private var uploadQueue: DispatchQueue
    
    init() {
        self.uploadQueue = DispatchQueue(label: "com.appsandwich.ppt2rk.rkupload", qos: .utility)
    }
    
    public func enqueueGPXData(_ data: Data, workout: PolarWorkout, handler: @escaping (RunkeeperActivity?) -> Void) {
        
        self.uploadQueue.async {
            
            let group = DispatchGroup()
            
            group.enter()
         
            Runkeeper.uploadGPXFileData(data, filename: workout.id + ".gpx", handler: { (activityWithConvertedData) in
                
                guard let convertedActivity = activityWithConvertedData else {
                    handler(nil)
                    group.leave()
                    return
                }
                
                Runkeeper.uploadActivity(convertedActivity, handler: { (uploadedActivity) in
                    
                    guard let activity = uploadedActivity else {
                        handler(nil)
                        group.leave()
                        return
                    }
                    
                    handler(activity)
                    group.leave()
                })
            })
            
            group.wait()
        }
    }
    
    public func pause() {
        self.uploadQueue.suspend()
    }
    
    public func resume() {
        self.uploadQueue.resume()
    }
}
