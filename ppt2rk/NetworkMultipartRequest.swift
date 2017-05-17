//
//  NetworkMultipartRequest.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 18/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class NetworkMultipartRequest {
    
    internal var boundaryString: String
    internal var uploadData: Data
    
    init() {
        
        self.uploadData = Data()
        self.boundaryString = "------WebKitFormBoundaryi9vuzfGd1APKHe1L"
    }
    
    public func contentTypeBoundaryString() -> String {
        return self.boundaryString.substring(from: self.boundaryString.index(self.boundaryString.startIndex, offsetBy: 2))
    }
    
    internal func appendOpeningHeaderIfNecessary() {
        
        guard self.uploadData.isEmpty else {
            return
        }
        
        let string = "\(self.boundaryString)\r\n"
        
        if let stringData = string.data(using: .utf8) {
            self.uploadData.append(stringData)
        }
    }
    
    public func appendData(_ data: Data, parameterName: String, filename: String, contentType: String?, finished: Bool) {
        
        self.appendOpeningHeaderIfNecessary()
        
        let separator = "\r\n"
        
        var string = "Content-Disposition: form-data; name=\"\(parameterName)\"; filename=\"\(filename)\"\(separator)"
        
        if let stringData = string.data(using: .utf8) {
            self.uploadData.append(stringData)
        }
        
        if let ct = contentType {
            
            string = "Content-Type: \(ct)\r\n\r\n"
            
            if let stringData = string.data(using: .utf8) {
                self.uploadData.append(stringData)
            }
        }
        
        self.uploadData.append(data)
        
        
        string = finished ? "--" : ""
        string = "\r\n\(self.boundaryString)\(string)\r\n"
        
        if let stringData = string.data(using: .utf8) {
            self.uploadData.append(stringData)
        }
    }
    
    public func appendValue(_ value: String, parameterName: String, finished: Bool) {
        
        self.appendOpeningHeaderIfNecessary()
        
        var string = "Content-Disposition: form-data; name=\"\(parameterName)\"\r\n\r\n"
        
        if let stringData = string.data(using: .utf8) {
            self.uploadData.append(stringData)
        }
        
        if let stringData = value.data(using: .utf8) {
            self.uploadData.append(stringData)
        }
        
        
        string = finished ? "--" : ""
        string = "\r\n\(self.boundaryString)\(string)\r\n"
        
        if let stringData = string.data(using: .utf8) {
            self.uploadData.append(stringData)
        }
    }
    
    public func data() -> Data {
        return self.uploadData
    }
}
