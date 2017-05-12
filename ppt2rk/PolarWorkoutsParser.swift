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
    }
    
    enum ParserState: UInt {
        case idle
        case item
        case timestamp
        case id
    }
    
    
    var data: Data
    var xmlParser: XMLParser
    
    var parserState: ParserState = .idle
    
    var workoutID: String?
    var workoutTimestamp: String?
    var workouts: [PolarWorkout] = []
    
    private var parseHandler: (([PolarWorkout]) -> Void)?
    
    
    init(data: Data) {
        
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
//        print("didStartElement: \(elementName)")
//        print("attributes: \(attributeDict)")
        
        if let type = attributeDict["type"], let elementType = ElementType.init(rawValue: type) {
            
            switch elementType {
                
            case .workout:
                
                if let id = attributeDict["id"] {
                    self.workoutID = id
                }
                
                self.parserState = .id
                
                break
                
            case .timestamp:
                
                if let name = attributeDict["name"] {
                    
                    if name == "created" {
                        self.parserState = .timestamp
                    }
                }
                
                break
                
            }
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        print("didEndElement: \(elementName)")
        
        // Only perform cleanup if returning to root.
        if self.parserState == .item && elementName == "item" {
            
            self.parserState = .idle
            
            guard let wID = self.workoutID, let wTS = self.workoutTimestamp else {
                self.workoutID = nil
                self.workoutTimestamp = nil
                return
            }
            
            let workout = PolarWorkout(id: wID, timestamp: wTS)
            workouts.append(workout)
            
            self.workoutID = nil
            self.workoutTimestamp = nil
        }
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
//        print("foundCharacters: \(string)")
        
        if self.parserState == .timestamp {
            self.workoutTimestamp = string
        }
        
        self.parserState = .item
    }
}
