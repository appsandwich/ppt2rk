//
//  Polar.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 11/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class Polar {
    
    class func stringForDate(_ date: Date) -> String {
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        df.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.SSS"
        return df.string(from: date)
    }
    
    class func loginWithEmail(_ email: String, password: String, handler: @escaping (Bool) -> Void) {
        
        print("Logging in as \(email)...")
        
        _ = Network.sendPOSTRequest("/index.ftl", bodyParams: [ "email" : email, "password" : password, ".action" : "login" ], contentType: .form, handler: { (d, e) in
            
            var loggedIn = false
            
            if let htmlString = d?.utf8String() {
                loggedIn = (htmlString.range(of: "<a href=\"/user/logout.ftl\">Log out</a>") != nil)
            }
            
            handler(loggedIn)
        })
    }
    
    class func loadWorkoutsSince(_ startDate: Date, handler: @escaping ([PolarWorkout]?) -> Void) {
        self.loadWorkoutsFrom(startDate, to: Date(), handler: handler)
    }
    
    class func loadWorkoutsFrom(_ startDate: Date, to endDate: Date, handler: @escaping ([PolarWorkout]?) -> Void) {
        
        let start = self.stringForDate(startDate)
        let end = self.stringForDate(endDate)
        
        print("Getting workouts from \(start) to \(end). This may take some time...")
        
        let xmlString = "<request><object name=\"root\"><prop name=\"startDate\" type=\"Timestamp\"><![CDATA[\(start)]]></prop><prop name=\"endDate\" type=\"Timestamp\"><![CDATA[\(end)]]></prop></object></request>"
        
        _ = Network.sendPOSTRequest("/user/calendar/index.xml?.action=items&rmzer=1494499701372", bodyParams: [ "xml" : xmlString ] , contentType: .xml, handler: { (d, e) in
            
            guard let data = d else {
                handler(nil)
                return
            }
            
            
            let parser = PolarWorkoutsParser(data: data)
            
            parser.parseWithHandler({ (workouts) in
                handler(workouts)
            })
        })
    }
    
    class func loadWorkoutsWithHandler(_ handler: @escaping ([PolarWorkout]?) -> Void) {
        
        /*
         
         curl -b pptcookies.txt --compressed -X POST 'https://www.polarpersonaltrainer.com/user/calendar/index.xml?.action=items&rmzer=1494499701372' --data '<request><object name="root"><prop name="startDate" type="Timestamp"><![CDATA[2010-05-01T00:00:00.000]]></prop><prop name="endDate" type="Timestamp"><![CDATA[2017-05-08T00:00:00.000]]></prop></object></request>' -H 'Accept: application/xml' -H 'Content-Type: application/xml'
         
         */
        
        let date = Date(timeIntervalSince1970: 0)
        self.loadWorkoutsSince(date, handler: handler)
    }
    
    class func exportGPXForWorkoutID(_ workoutID: String, handler: @escaping (Data?) -> Void) {
        
        print("Exporting GPX for workout \(workoutID)...")
        
        // curl -b pptcookies.txt -d 'items.0.item=777850771&items.0.itemType=OptimizedExercise&.filename=filename&.action=gpx' https://www.polarpersonaltrainer.com/user/calendar/index.gpx
        
        _ = Network.sendPOSTRequest("/user/calendar/index.gpx", bodyParams: [ "items.0.item" : workoutID, "items.0.itemType" : "OptimizedExercise", ".filename" : workoutID + ".gpx", ".action" : "gpx" ], contentType: .form, handler: { (d, e) in
            handler(d)
        })
    }
}
