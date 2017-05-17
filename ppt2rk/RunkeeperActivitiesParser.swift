//
//  RunkeeperActivitiesParser.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 17/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class RunkeeperActivitiesParser {
    
    var data: Data? = nil
    
    init(_ data: Data) {
        self.data = data
    }
    
    public func parseWithHandler(_ handler: @escaping ([RunkeeperActivity]?) -> Void) {
        
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
        
        guard let activities = dictionary["activities"] as? Dictionary<String, Any> else {
            handler(nil)
            return
        }
        
        guard let year = activities.values.first as? Dictionary<String, Any> else {
            handler(nil)
            return
        }
        
        guard let month = year.values.first as? [Dictionary<String, Any>], month.count > 0 else {
            handler(nil)
            return
        }
        
        let runkeeperActivities: [RunkeeperActivity] = month.flatMap { (activity) -> RunkeeperActivity? in
            
            if let id = activity["activity_id"] as? Int, let distance = activity["distance"] as? String, let elapsedTime = activity["elapsedTime"] as? String, let dayOfMonth = activity["dayOfMonth"] as? String, let monthNum = activity["monthNum"] as? String, let year = activity["year"] as? String, let timestamp = RunkeeperActivitiesParser.dateFrom(dayOfMonth, monthNum: monthNum, year: year) {
                
                let timeComps = elapsedTime.components(separatedBy: ":")
                
                var durationInSeconds = 0.0
                
                for (index, timeComp) in timeComps.enumerated() {
                    
                    guard let s = Double(timeComp) else {
                        continue
                    }
                    
                    let seconds = s * NSDecimalNumber(decimal: pow(60.0, timeComps.count - (index + 1))).doubleValue
                    
                    guard seconds > 0.0 else {
                        continue
                    }
                    
                    durationInSeconds += seconds
                }
                
                return RunkeeperActivity(id: id, timestamp: timestamp, distance: distance, duration: "\(durationInSeconds)", day: dayOfMonth + "/" + monthNum + "/" + year)
            }
            else {
                return nil
            }
        }
        
        handler(runkeeperActivities)
    }
    
    class func dateFrom(_ dayOfMonth: String, monthNum: String, year: String) -> Date? {
        
        let dateString = dayOfMonth + "/" + monthNum + "/" + year
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        df.dateFormat = "d/MM/yyyy"
        
        return df.date(from: dateString)
    }
}
