//
//  Runkeeper.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 17/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class Runkeeper {
    
    class func loginWithEmail(_ email: String, password: String, handler: @escaping (String?) -> Void) {
        
        print("Logging in to Runkeeper as \(email)...")
        
        _ = Network.sendPOSTRequest(.runkeeper, path: "/login", bodyParams: [ "email" : email, "password" : password, "_eventName" : "submit" ], contentType: .form, handler: { (d, e) in
            
            var username: String? = nil
            
            if let htmlString = d?.utf8String() {
                
                if (htmlString.range(of: "<script>window.isUserLoggedIn = \"{User id=") != nil) {
                    
                    //  username=USERNAME appLanguage=WHATEVER
                    
                    if let startRange = htmlString.range(of: " email="), let endRange = htmlString.range(of: " name=") {
                        
                        if startRange.upperBound < endRange.lowerBound {
                            
                            let usernameRange = startRange.upperBound..<endRange.lowerBound
                            
                            username = htmlString.substring(with: usernameRange)
                        }
                    }
                }
            }
            
            handler(username)
        })
    }
    
    class func loadActivitiesForUsername(_ username: String, month: Date, handler: @escaping ([RunkeeperActivity]?) -> Void) {
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        df.dateFormat = "MMM-'01'-yyyy"
        
        let dateString = df.string(from: month)
        
        self.loadActivitiesForUsername(username, month: dateString, handler: handler)
    }
    
    class func loadActivitiesForUsername(_ username: String, month: String, handler: @escaping ([RunkeeperActivity]?) -> Void) {
        
        // https://runkeeper.com/activitiesByDateRange?userName=USERNAME&startDate=Jun-01-2016
        
        print("Getting Runkeeper activities for month beginning \(month)...")
        
        _ = Network.sendGETRequest(.runkeeper, path: "/activitiesByDateRange?userName=\(username)&startDate=\(month)", contentType: .json, handler: { (d, e) in
            
            guard let data = d, e == nil else {
                handler(nil)
                return
            }
            
            let parser = RunkeeperActivitiesParser(data)
            
            parser.parseWithHandler({ (activities) in
                handler(activities)
            })
        })
    }
    
    class func uploadGPXFileData(_ gpxData: Data, filename: String, handler: @escaping (RunkeeperActivity?) -> Void) {
        
        let request = NetworkMultipartRequest()
        
        request.appendValue(".gpx", parameterName: "uploadType", finished: false)
        request.appendData(gpxData, parameterName: "trackFile", filename: filename, contentType: "application/octet-stream", finished: true)
        
        _ = Network.sendMultipartRequest(request, to: .runkeeper, path: "/trackFileUpload", handler: { (d, e) in
            
            guard let data = d, e == nil else {
                handler(nil)
                return
            }
            
            let parser = RunkeeperGPXUploadParser(data)
            
            parser.parseWithHandler(handler)
        })
    }
    
    class func uploadActivity(_ activity: RunkeeperActivity, handler: @escaping (RunkeeperActivity?) -> Void) {
        
        guard let points = activity.convertedFromGPXString else {
            handler(nil)
            return
        }
        
        /*
         
         
 
        */
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        
        // 2014/3/17 10:49:45.000
        df.dateFormat = "yyyy/M/d' 'HH:mm:ss.SSS"
        
        let request = NetworkMultipartRequest()
        
        request.appendValue("save", parameterName: "_eventName", finished: false)
        
        request.appendValue("gpx", parameterName: "importFormat", finished: false)
        request.appendValue("", parameterName: "heartRateGraphJson", finished: false)
        
        request.appendData(Data(), parameterName: "trackFile", filename: "", contentType: "application/octet-stream", finished: false)
        
        request.appendValue("FRIENDS", parameterName: "activityMapViewableBy", finished: false)
        request.appendValue("true", parameterName: "hasMap", finished: false)
        request.appendValue("true", parameterName: "mapEdited", finished: false)
        request.appendValue("false", parameterName: "caloriesEdited", finished: false)
        request.appendValue("0", parameterName: "durationMs", finished: false)
        request.appendValue(points, parameterName: "points", finished: false)
        request.appendValue("", parameterName: "route", finished: false)
        request.appendValue("RUN", parameterName: "activityType", finished: false)
        request.appendValue("NONE", parameterName: "gymEquipment", finished: false)
        request.appendValue(df.string(from: activity.timestamp), parameterName: "startTimeString", finished: false)
        request.appendValue("", parameterName: "averageHeartRate", finished: false)
        
        request.appendData(Data(), parameterName: "hrmFile", filename: "", contentType: "application/octet-stream", finished: false)
        
        if let duration = Double(activity.duration) {
            
            let hours = floor(duration / 3600.0)
            let hoursInt = Int(hours)
            let hoursString = hoursInt > 9 ? "\(hoursInt)" : "0\(hoursInt)"
            request.appendValue(hoursString, parameterName: "durationHours", finished: false)
            
            let mins = floor((duration - (hours * 3600.0)) / 60.0)
            let minsInt = Int(mins)
            let minsString = minsInt > 9 ? "\(minsInt)" : "0\(minsInt)"
            
            request.appendValue(minsString, parameterName: "durationMinutes", finished: false)
            
            let seconds = duration - (hours * 3600.0) - (mins * 60.0)
            let secondsInt = Int(seconds)
            let secondsString = secondsInt > 9 ? "\(secondsInt)" : "0\(secondsInt)"
            
            request.appendValue(secondsString, parameterName: "durationSeconds", finished: false)
        }
        
        df.dateFormat = "hh"
        request.appendValue(df.string(from: activity.timestamp), parameterName: "startHour", finished: false)
        
        df.dateFormat = "mm"
        request.appendValue(df.string(from: activity.timestamp), parameterName: "startMinute", finished: false)
        
        df.dateFormat = "a"
        
        let amString = df.string(from: activity.timestamp)
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = df.locale
        calendar.timeZone = df.timeZone
        
        request.appendValue(amString == calendar.amSymbol ? "true" : "false", parameterName: "am", finished: false)
        
        
        if let distanceInMeters = Double(activity.distance) {
            
            let distanceInKm = distanceInMeters / 1000.0
            request.appendValue(String(format: "%.2f", distanceInKm), parameterName: "distance", finished: false)
        }
        
        request.appendValue("", parameterName: "calories", finished: false)
        
        request.appendValue("PRIVATE", parameterName: "activityViewableBy", finished: false)
        
        request.appendValue("", parameterName: "notes", finished: false)
        
        request.appendValue("v4sDxYjbHbI44FUJ4tA88m2FrHvkk1Zoq_D-idYqVNgnkKqsSjwMGg==", parameterName: "_sourcePage", finished: false)
        request.appendValue("O1sQchdWoRYkp2TCPzUteY5himp8zSjJM1tqnMLbTAj8zELRbHP_pY1nwiDN_Cmt9Dc5N9aXpD8BvzTkQWp25w==", parameterName: "__fp", finished: true)
        
        _ = Network.sendMultipartRequest(request, to: .runkeeper, path: "/new/activity", handler: { (d, e) in
            
            guard let data = d, e == nil else {
                handler(nil)
                return
            }
            
            //TODO: exract activity ID
            
            guard let htmlString = data.utf8String(), htmlString.range(of: "<title>Running Activity ") != nil else {
                handler(nil)
                return
            }
            
            // href=\"/delete/activity?activityId=987100887\" alertTitle=\"Delete Activity?\">
            
            let startString = "href=\"/delete/activity?activityId="
            
            let endString = "\" alertTitle=\"Delete Activity?\">"
            
            guard let startRange = htmlString.range(of: startString), let endRange = htmlString.range(of: endString), startRange.upperBound < endRange.lowerBound else {
                handler(nil)
                return
            }
            
            
            let idRange = startRange.upperBound..<endRange.lowerBound
            
            let activityID = htmlString.substring(with: idRange)
            
            guard activityID.characters.count > 0, let aID = Int(activityID), aID > 0 else {
                handler(nil)
                return
            }
            
            activity.id = aID
            
            handler(activity)
        })
    }
}
