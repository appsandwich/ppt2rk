//
//  Credentials.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 17/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation

class Credentials {
    
    let polarService = "com.appsandwich.ppt2rk.polar"
    let runkeeperService = "com.appsandwich.ppt2rk.runkeeper"
    
    var argsParser: ArgsParser
    
    init(_ argsParser: ArgsParser) {
        self.argsParser = argsParser
        self.autoSaveToKeychain()
    }
    
    internal func autoSaveToKeychain() {
        
        guard self.argsParser.hasArgumentOfType(.keychain) else {
            return
        }
        
        if let polarEmail = self.argsParser.argumentForType(.polarEmail)?.value, let polarPassword = self.argsParser.argumentForType(.polarPassword)?.value {
            self.saveEmail(polarEmail, password: polarPassword, argumentType: .polarPassword)
        }
        
        if let runkeeperEmail = self.argsParser.argumentForType(.runkeeperEmail)?.value, let runkeeperPassword = self.argsParser.argumentForType(.runkeeperPassword)?.value {
            self.saveEmail(runkeeperEmail, password: runkeeperPassword, argumentType: .runkeeperPassword)
        }
    }
    
    internal func credentialForArgumentType(_ argumentType: ArgumentType) -> String? {
        
        switch argumentType {
        case .polarEmail:
            fallthrough
        case .polarPassword:
            fallthrough
        case .runkeeperEmail:
            fallthrough
        case .runkeeperPassword:
            break
        default:
            return nil
        }
        
        if let value = self.argsParser.argumentForType(argumentType)?.value {
            return value
        }
        
        guard self.argsParser.hasArgumentOfType(.keychain) else {
            return nil
        }
        
        let service = argumentType == .runkeeperEmail ? self.runkeeperService : self.polarService
        
        var passwordItems: [KeychainPasswordItem]? = nil
        
        do {
            try passwordItems = KeychainPasswordItem.passwordItems(forService: service)
        }
        catch {
            return nil
        }
        
        guard let pws = passwordItems, pws.count > 0 else {
            return nil
        }
        
        var email: String? = nil
        
        switch argumentType {
        case .runkeeperEmail:
            fallthrough
        case .polarEmail:
            return pws.first?.account
            
        case .runkeeperPassword:
            email = self.credentialForArgumentType(.runkeeperEmail)
            fallthrough
        case .polarPassword:
            
            if email == nil {
                email = self.credentialForArgumentType(.polarEmail)
            }
            
            // If no email provided, read first item.
            guard let e = email else {
             
                do {
                    return try pws.first?.readPassword()
                }
                catch {
                    return nil
                }
            }
            
            
            // If email provided, find matching credentials.
            guard let match = pws.first(where: { (kpi) -> Bool in
                return kpi.account == e
            }) else {
                return nil
            }
            
            do {
                return try match.readPassword()
            }
            catch {
                return nil
            }
            
            
        default:
            return nil
            
        }
    }
    
    // MARK: - Read
    
    public func polarEmail() -> String? {
        return self.credentialForArgumentType(.polarEmail)
    }
    
    public func polarPassword() -> String? {
        return self.credentialForArgumentType(.polarPassword)
    }
    
    public func runkeeperEmail() -> String? {
        return self.credentialForArgumentType(.runkeeperEmail)
    }
    
    public func runkeeperPassword() -> String? {
        return self.credentialForArgumentType(.runkeeperPassword)
    }
    
    // MARK: - Write
    
    public func saveEmail(_ email: String, password: String, argumentType: ArgumentType) {
        
        var service: String
        
        switch argumentType {
        case .polarEmail:
            fallthrough
        case .polarPassword:
            service = self.polarService
            break
            
        case .runkeeperEmail:
            fallthrough
        case .runkeeperPassword:
            service = self.runkeeperService
            break
            
        default:
            print("Invalid argument type for keychain service.")
            return
        }
        
        let credential = KeychainPasswordItem(service: service, account: email)
        
        do {
            try credential.savePassword(password)
        }
        catch {
            print("Failed to save to keychain service: \(service).")
        }
    }
}
