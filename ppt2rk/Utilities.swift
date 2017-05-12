//
//  Utilities.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 12/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

extension Data {
    
    public func utf8String() -> String? {
        return String(data: self, encoding: .utf8)
    }
}
