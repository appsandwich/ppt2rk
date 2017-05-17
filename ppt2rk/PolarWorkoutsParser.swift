//
//  PolarWorkoutsParser.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 11/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class PolarWorkoutsParser: NSObject, XMLParserDelegate {
    
    enum ElementType: String {
        case workout = "OptimizedExercise"
        case timestamp = "Timestamp"
        case number = "Number"
        case duration = "Duration"
    }
    
    enum ParserState: UInt {
        case idle
        case item
        case timestamp
        case id
        case distance
        case duration
    }
    
    
    var data: Data
    var xmlParser: XMLParser
    
    var parserState: ParserState = .idle
    var itemLevel = 0
    
    var workoutID: String?
    var workoutTimestamp: String?
    var workoutDistance: String?
    var workoutDuration: String?
    var workouts: [PolarWorkout] = []
    
    var polarDateFormatter, runkeeperMonthDateFormatter, runkeeperDayDateFormatter: DateFormatter
    
    private var parseHandler: (([PolarWorkout]) -> Void)?
    
    
    init(data: Data) {
        
        self.polarDateFormatter = DateFormatter()
        self.polarDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.polarDateFormatter.timeZone = TimeZone(identifier: "UTC")
        self.polarDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        self.runkeeperMonthDateFormatter = DateFormatter()
        self.runkeeperMonthDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.runkeeperMonthDateFormatter.timeZone = TimeZone(identifier: "UTC")
        self.runkeeperMonthDateFormatter.dateFormat = "MMM-'01'-yyyy"
        
        self.runkeeperDayDateFormatter = DateFormatter()
        self.runkeeperDayDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.runkeeperDayDateFormatter.timeZone = TimeZone(identifier: "UTC")
        self.runkeeperDayDateFormatter.dateFormat = "d/MM/yyyy"
        
        self.data = data
        self.xmlParser = XMLParser(data: data)
        
        super.init()
    }
    
    public func parseWithHandler(_ handler: @escaping ([PolarWorkout]) -> Void) {
        
        self.parseHandler = handler
        
        self.xmlParser.delegate = self
        self.xmlParser.parse()
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
        //print("Parsing XML...")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        //print("Finished parsing.")
        
        guard let handler = self.parseHandler else {
            return
        }
        
        handler(self.workouts)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        //print("didStartElement: \(elementName)")
        //print("attributes: \(attributeDict)")
        
        if elementName == "item" {
            self.itemLevel += 1
        }
        
        if let type = attributeDict["type"], let elementType = ElementType.init(rawValue: type) {
            
            switch elementType {
                
            case .workout:
                
                if let id = attributeDict["id"] {
                    self.workoutID = id
                }
                
                self.parserState = .id
                
                break
                
            case .timestamp:
                
                if let name = attributeDict["name"], self.itemLevel == 1 {
                    
                    if name == "websyncId" {
                        self.parserState = .timestamp
                    }
                }
                
                break
                
            case .number:
                
                if let name = attributeDict["name"] {
                    
                    if name == "distance" {
                        self.parserState = .distance
                    }
                }
                
                break
                
            
            case .duration:
                
                if let name = attributeDict["name"] {
                    
                    if name == "duration" {
                        self.parserState = .duration
                    }
                }
                
                break
            }
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        print("didEndElement: \(elementName)")
        
        // Only perform cleanup if returning to root.
        
        if elementName == "item" {
            self.itemLevel -= 1
        }
        
        if self.itemLevel == 1 && self.parserState == .item && elementName == "item" {
            
            self.parserState = .idle
            
            guard let wID = self.workoutID, let wTS = self.workoutTimestamp, let wDist = self.workoutDistance, let wDur = self.workoutDuration else {
                self.workoutID = nil
                self.workoutTimestamp = nil
                self.workoutDistance = nil
                self.workoutDuration = nil
                return
            }
            
     
            var runkeeperMonth, runkeeperDay: String?
            
            if let date = self.polarDateFormatter.date(from: wTS) {
                runkeeperMonth = self.runkeeperMonthDateFormatter.string(from: date)
                runkeeperDay = self.runkeeperDayDateFormatter.string(from: date)
            }
    
            
            let workout = PolarWorkout(id: wID, timestamp: wTS, distance: wDist, duration: wDur, runkeeperMonth: runkeeperMonth, runkeeperDay: runkeeperDay)
            workouts.append(workout)
            
            self.workoutID = nil
            self.workoutTimestamp = nil
            self.workoutDistance = nil
            self.workoutDuration = nil;
        }
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
//        print("foundCharacters: \(string)")
        
        switch self.parserState {
        case .timestamp:
            
            guard self.itemLevel == 1 else {
                break
            }
            
            self.workoutTimestamp = string
            
            break
        case .distance:
            self.workoutDistance = string
            break
        case .duration:
            self.workoutDuration = string
            break
        default:
            break
        }
        
        self.parserState = .item
    }
}
