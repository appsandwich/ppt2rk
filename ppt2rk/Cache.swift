//
//  Cache.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 12/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class Cache {
    
    class func cachesDirectory() -> String? {
        
        guard let cache = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        let fm = FileManager.default
        
        let subDir = cache + "/ppt2rk"
        
        if !fm.fileExists(atPath: subDir) {
            
            do {
                try fm.createDirectory(atPath: subDir, withIntermediateDirectories: false, attributes: nil)
            }
            catch {
                return nil
            }
        }
        
        return subDir
    }
    
    class func cacheGPXData( _ gpx: Data, filename: String) -> URL? {
        
        guard let dir = self.cachesDirectory() else {
            return nil
        }
        
        let path = dir + "/\(filename).gpx"
        
        let url = URL(fileURLWithPath: path)
        
        do {
            try gpx.write(to: url)
        }
        catch {
            print("Failed to write GPX file to \(url).")
            return nil
        }
        
        return url
    }
}
