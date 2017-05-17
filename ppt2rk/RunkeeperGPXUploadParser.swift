//
//  RunkeeperGPXUploadParser.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 18/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class RunkeeperGPXUploadParser {
    
    var data: Data? = nil
    
    init(_ data: Data) {
        self.data = data
    }
    
    public func parseWithHandler(_ handler: @escaping (RunkeeperActivity?) -> Void) {
        
        guard let data = self.data else {
            handler(nil)
            return
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            handler(nil)
            return
        }
        
        guard let dictionary = json as? Dictionary<String, Any> else {
            handler(nil)
            return
        }
        
        if let error = dictionary["error"] as? String, error.characters.count > 0 {
            handler(nil)
            return
        }
        
        guard let trackImportData = dictionary["trackImportData"] as? Dictionary<String, Any> else {
            handler(nil)
            return
        }
        
        guard let duration = trackImportData["duration"] as? Double, let startTime = trackImportData["startTime"] as? Int, let trackPoints = trackImportData["trackPoints"] as? Array< Dictionary<String, Any> >, trackPoints.count > 0 else {
            handler(nil)
            return
        }
        
        // Thanks to https://medium.com/@ndcrandall/automating-gpx-file-imports-in-runkeeper-f446917f8a19
        //str << "#{point['type']},#{point['latitude']},#{point['longitude']},#{point['deltaTime']},0,#{point['deltaDistance']};"
        
        var totalDistance = 0.0
        
        let runkeeperString = trackPoints.reduce("") { (string, trackPoint) -> String in
            
            guard let type = trackPoint["type"] as? String, let latitude = trackPoint["latitude"] as? Double, let longitude = trackPoint["longitude"] as? Double, let deltaTime = trackPoint["deltaTime"] as? Double, let deltaDistance = trackPoint["deltaDistance"] as? Double else {
                return string
            }
            
            let trackPointString = "\(type),\(latitude),\(longitude),\(Int(deltaTime)),0,\(deltaDistance);"
            
            totalDistance += deltaDistance
            
            return string + trackPointString
        }
        
        
        let date = Date(timeIntervalSince1970: Double(startTime) / 1000.0)
        
        let runkeeperActivity = RunkeeperActivity(id: -1, timestamp: date, distance: "\(totalDistance)", duration: "\(duration / 1000.0)", day: "")
        
        runkeeperActivity.convertedFromGPXString = runkeeperString
        
        handler(runkeeperActivity)
    }
}
