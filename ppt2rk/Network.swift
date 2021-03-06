//
//  Network.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 11/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class Network {
    
    enum Endpoint: String {
        case polar = "https://www.polarpersonaltrainer.com"
        case runkeeper = "https://runkeeper.com"
    }
    
    enum ContentType: String {
        case form = "application/x-www-form-urlencoded"
        case xml = "application/xml"
        case json = "application/json;charset=UTF-8"
    }
    
    class func sendRequest(_ endpoint: Endpoint, path: String, method: String, bodyParams: Dictionary<String, Any>?, contentType: ContentType, handler: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask? {
        
        guard let url = URL(string: endpoint.rawValue + path) else {
            handler(nil, nil)
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let bp = bodyParams {
            
            var data: Data? = nil
            
            switch contentType {
                
            case .form:
                
                var formParams: [String] = []
                
                bodyParams?.forEach({ (k, v) in
                    
                    guard v is String else {
                        return
                    }
                    
                    formParams.append("\(k)=\(v as! String)")
                })
                
                
                let formString = formParams.joined(separator: "&")
                
                //print("\(formString)")
                
                data = formString.data(using: .utf8)
                
                break
                
            case .xml:
                
                if let xmlString = bodyParams?.first?.value, xmlString is String {
                    //print("\(xmlString)")
                    data = (xmlString as! String).data(using: .utf8)
                }
                
                break
                
            case .json:
                
                do {
                    data = try JSONSerialization.data(withJSONObject: bp, options: .init(rawValue: 0))
                }
                catch let error as NSError {
                    print("\(error)")
                    handler(nil, error)
                    return nil
                }
                
                break
            }
            
            
            if let d = data {
                
                request.httpBody = d
                
                request.setValue("\(d.count)", forHTTPHeaderField: "Content-Length")
                request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
                
                request.setValue("*/*", forHTTPHeaderField: "Accept")
                request.setValue(url.host!, forHTTPHeaderField: "Host")
                request.setValue("curl/7.51.0", forHTTPHeaderField: "User-Agent")
            }
            
        }
        
        //print("\(method) \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler:  { (data, response, error) in
            
            DispatchQueue.global(qos: .background).async {
                handler(data, error)
            }
        })
        
        task.resume()
        
        return task
    }
    
    class func sendGETRequest(_ endpoint: Endpoint, path: String, contentType: ContentType, handler: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask? {
        return self.sendRequest(endpoint, path: path, method: "GET", bodyParams: nil, contentType: contentType, handler: handler)
    }
    
    class func sendPUTRequest(_ endpoint: Endpoint, path: String, bodyParams: Dictionary<String, Any>?, contentType: ContentType, handler: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask? {
        return self.sendRequest(endpoint, path: path, method: "PUT", bodyParams: bodyParams, contentType: contentType, handler: handler)
    }
    
    class func sendPOSTRequest(_ endpoint: Endpoint, path: String, bodyParams: Dictionary<String, Any>?, contentType: ContentType, handler: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask? {
        return self.sendRequest(endpoint, path: path, method: "POST", bodyParams: bodyParams, contentType: contentType, handler: handler)
    }
    
    class func sendMultipartRequest(_ multipartRequest: NetworkMultipartRequest, to endpoint: Endpoint, path: String, handler: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask? {
        
        guard let url = URL(string: endpoint.rawValue + path) else {
            handler(nil, nil)
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("multipart/form-data; boundary=\(multipartRequest.contentTypeBoundaryString())", forHTTPHeaderField: "Content-Type")
        
        let data = multipartRequest.data()
        
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        
        request.httpBody = data;

        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue(url.host!, forHTTPHeaderField: "Host")
        request.setValue("curl/7.51.0", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler:  { (data, response, error) in
            
            DispatchQueue.global(qos: .background).async {
                handler(data, error)
            }
        })
        
        task.resume()
        
        return task
    }
}
