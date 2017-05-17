//
//  ArgsParser.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 15/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class Arg {
    
    var type: ArgumentType
    var key: String
    var value: String?
    
    init(key: String, type: ArgumentType, value: String?) {
        
        self.key = key
        self.type = type
        self.value = value
    }
    
    public func downloadValueIndexesForItemCount(_ itemCount: Int) -> [Int]? {
        
        guard self.type == .download, let v = self.value else {
            return nil
        }
        
        return DownloadArgumentValue.indexesForRawString(v, numberOfItems: itemCount)
    }
}

extension Arg: Equatable {}

// MARK: Equatable

func ==(lhs: Arg, rhs: Arg) -> Bool {
    return lhs.type == rhs.type
}


enum ArgumentType: String {
    
    case polarEmail = "email"
    case polarPassword = "password"
    case runkeeperEmail = "rkemail"
    case runkeeperPassword = "rkpassword"
    case download = "download"
    case reset = "reset"
    case keychain = "keychain"
    
    static func all() -> [ArgumentType] {
        return [.polarEmail, .polarPassword, .runkeeperEmail, .runkeeperPassword, .download, .reset, .keychain]
    }
    
    func expectsValue() -> Bool {
        
        switch self {
        case .reset:
            fallthrough
        case .keychain:
            return false
        default:
            return true
        }
    }
    
    func shortVersion() -> String {
        
        switch self {
        case .runkeeperEmail:
            return "-rke"
        case .runkeeperPassword:
            return "-rkp"
        default:
            return "-" + String(describing: self.rawValue.characters.first!)
        }
    }
    
    func longVersion() -> String {
        
        switch self {
        case .runkeeperEmail:
            return "--rkemail"
        case .runkeeperPassword:
            return "--rkpassword"
        default:
            return "--" + self.rawValue
        }
    }
    
    func matchesString(_ string: String) -> Bool {
        return self.shortVersion() == string || self.longVersion() == string
    }
    
    
    static func forString(_ string: String) -> ArgumentType? {
        
        guard string.hasPrefix("-") else {
            return nil
        }
        
        
        let isLongVersion = string.hasPrefix("--")
        
        if isLongVersion {
            
            let rawString = string.replacingOccurrences(of: "-", with: "")
            
            return ArgumentType(rawValue: rawString)
        }
        else {
            
            var arg: ArgumentType? = nil
            
            let allArgs = ArgumentType.all()
            
            allArgs.forEach({ (a) in
                
                if a.shortVersion() == string {
                    arg = a
                    return
                }
            })
            
            return arg
        }
        
    }
}

enum DownloadArgumentValue: String {
    
    case all = "all"
    case first = "first"
    case last = "last"
    case sync = "sync"
    case runkeeper = "runkeeper"
    
    static func indexesForRawString(_ string: String, numberOfItems: Int) -> [Int]? {
        
        if let value = DownloadArgumentValue(rawValue: string) {
            
            switch value {
            case .all:
                return [-1]
            case .first:
                return [1]
            case .last:
                return [numberOfItems - 1]
            case .sync:
                fallthrough
            case .runkeeper:
                return nil
            }
        }
        else {
            
            if string.contains(DownloadArgumentValue.first.rawValue) {
                
                if let lastChar = string.characters.last {
                    
                    if let count = Int("\(lastChar)") , count > 0 {
                        return Array(0...(count - 1))
                    }
                }
            }
            else if string.contains(DownloadArgumentValue.last.rawValue) {
                
                if let lastChar = string.characters.last {
                    
                    if let count = Int("\(lastChar)") , count > 0 {
                        return Array(1...count).map({ (index) -> Int in
                            return numberOfItems - index
                        })
                    }
                }
            }
        }
        
        return [numberOfItems - 1]
    }
}

class ArgsParser {
    
    var arguments: [Arg]
    
    init(_ args: [String]) {
        
        self.arguments = []
        
        for (index, argument) in args.enumerated() {
            
            if let type = ArgumentType.forString(argument) {
                
                if type.expectsValue() && (index + 1) < args.count {
                    
                    let value = args[index + 1]
                    
                    guard value.characters.count > 0 else {
                        continue
                    }
                    
                    let arg = Arg(key: argument, type:type, value: value)
                    self.arguments.append(arg)
                }
                else if !type.expectsValue() {
                    
                    let arg = Arg(key: argument, type:type, value: nil)
                    self.arguments.append(arg)
                }
                else {
                    // Invalid arg
                }
            }
        }
    }
    
    public func argumentForType(_ type: ArgumentType) -> Arg? {
        
        guard self.arguments.count > 0 else {
            return nil
        }
        
        let args = self.arguments.filter { (arg) -> Bool in
            arg.type == type
        }
        
        guard args.count > 0 else {
            return nil
        }
        
        return args.first
    }
    
    public func valueForArgumentType(_ type: ArgumentType) -> String? {
        
        guard let arg = self.argumentForType(type) else {
            return nil
        }
        
        return arg.value
    }
    
    public func hasArgumentOfType(_ type: ArgumentType) -> Bool {
        return self.argumentForType(type) != nil
    }
    
}
