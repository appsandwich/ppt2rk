//
//  main.swift
//  ppt2rk
//
//  Created by Vinny Coyne on 11/05/2017.
//  Copyright © 2017 App Sandwich Limited. All rights reserved.
//

import Foundation


enum ExitCode: Int32 {
    case unknown = 1
    case badArgument = 2
    case loginFailed = 3
    case noKeychainItems = 4
    case keychainSaveFailed = 5
}

let semaphore = DispatchSemaphore(value: 0)

func exitApp() {
    semaphore.signal()
}

func exitWithErrorCode(_ code: ExitCode) {
    exit(code.rawValue)
}

func printHelp() {
    print("Usage: ppt2rk --email youremail@address.com --password yourpolarpassword")
}

func runApp(email: String, password: String, args: ArgsParser) {
    
    Polar.loginWithEmail(email, password: password, handler: { (loggedIn) in
        
        guard loggedIn == true else {
            print("Error: Login failed.")
            exitWithErrorCode(.loginFailed)
            return
        }
        
        Polar.loadWorkoutsWithHandler({ (workouts) in
            
            if let ws = workouts, ws.count > 0 {
                
                guard let arg = args.argumentForType(.download), let argValue = arg.value else {
                    promptWithWorkouts(ws)
                    return
                }
                
                
                if let indexes = arg.downloadValueIndexesForItemCount(ws.count) {
                    downloadWorkoutsAtIndexes(indexes, workouts: workouts!, showPromptWhenFinished: false)
                }
                else if let v = DownloadArgumentValue(rawValue: argValue), v == .sync {
                    
                    // Sync mode
                    
                    print("Performing sync...")
                    
                    if let ids = PolarWorkout.downloadedWorkoutIDs() {
                        
                        let workoutsToDownload = ws.filter({ (workout) -> Bool in
                            return ids.index(of: workout.id) == nil
                        })
                        
                        switch workoutsToDownload.count {
                        case 0:
                            print("No new workouts.")
                            break
                        case 1:
                            print("1 new workout.")
                            break
                        default:
                            print("\(workoutsToDownload.count) new workouts.")
                            break
                        }
                        
                        downloadWorkouts(workoutsToDownload, showPromptWhenFinished: false)
                    }
                    else {
                        downloadWorkouts(ws, showPromptWhenFinished: false)
                    }
                }
                else {
                    promptWithWorkouts(ws)
                }
            }
        })
    })
    
    semaphore.wait()
}

func downloadWorkoutsAtIndexes(_ indexes: [Int], workouts: [PolarWorkout], showPromptWhenFinished: Bool) {
    
    var workoutsToDownload: [PolarWorkout] = []
    
    if indexes.index(of: -1) == nil {
        
        for (index, workout) in workouts.enumerated() {
            
            if indexes.index(of: index) != nil {
                workoutsToDownload.append(workout)
            }
        }
    }
    else {
        workoutsToDownload.append(contentsOf: workouts)
    }
    
    downloadWorkouts(workoutsToDownload, showPromptWhenFinished: showPromptWhenFinished)
}

func downloadWorkouts( _ workouts: [PolarWorkout], showPromptWhenFinished: Bool) {
    
    guard workouts.count > 0 else {
        exitApp()
        return
    }
    
    
    let group = DispatchGroup()
    
    workouts.forEach { (workout) in
        
        group.enter()
        
        Polar.exportGPXForWorkoutID(workout.id, handler: { (gpxData) in
            
            guard let data = gpxData else {
                group.leave()
                return
            }
            
            if let url = Cache.cacheGPXData(data, filename: workout.id) {
                print("GPX saved to \(url).")
                workout.markAsDownloaded()
            }
            
            group.leave()
        })
        
    }
    
    group.wait()
    
    if showPromptWhenFinished {
        promptWithWorkouts(workouts)
    }
    else {
        exitApp()
    }
}

func promptWithWorkouts(_ workouts: [PolarWorkout]) {
    
    print("***********************************************************")
    let workoutString = workouts.count == 1 ? "workout" : "workouts"
    print("\(workouts.count) \(workoutString) found. Pick one to export to GPX.")
    print("[Index]\t\tWorkout ID\t\tTimestamp")
    
    for (index, workout) in workouts.enumerated() {
        print("[\(index + 1)]\t\t\(workout.id)\t\t\(workout.timestamp)")
    }
    
    print("\n\n\(workouts.count) \(workoutString) found. Pick one to export to GPX.")
    print("***********************************************************")
    print("To download a single file, enter a value from 1 to \(workouts.count), then hit Return.")
    print("To download multiple files, enter values separated by space or comma (e.g. 1,2,3,4,5) then hit Return.")
    print("To download all files, enter 0 then hit Return.")
    print("Or, hit Return to quit.")
    
    guard let response = readLine() else {
        exitApp()
        return
    }
    
    let comps = response.components(separatedBy: CharacterSet.init(charactersIn: " ,"))
    
    guard comps.count > 0 else {
        exitApp()
        return
    }
    
    let indexes: [Int] = comps.map { (s) -> Int in
        
        guard let index = Int(s) else {
            return -1
        }
        
        return index
    }
    
    
    guard indexes.index(of: -1) == nil else {
        exitApp()
        return
    }
    
    // Shift indexes
    let shiftedIndexes = indexes.map { (index) -> Int in
        return index - 1
    }
    
    downloadWorkoutsAtIndexes(shiftedIndexes, workouts: workouts, showPromptWhenFinished: true)
}

// MARK: - main()

let arguments = CommandLine.arguments

let argsParser = ArgsParser(arguments)

if argsParser.hasArgumentOfType(.reset) {
    print("Removing list of downloaded workouts.")
    PolarWorkout.resetDownloadedWorkoutIDs()
}


var email = argsParser.argumentForType(.email)
var password = argsParser.argumentForType(.password)
var passwordValue = password?.value

if argsParser.hasArgumentOfType(.email) && passwordValue == nil {
    print("Please enter a password to continue: ")
    passwordValue = readLine()
}

if let e = email?.value, let p = passwordValue {
    
    if argsParser.hasArgumentOfType(.keychain) {
        // Save to keychain
        
        let keychainItem = KeychainPasswordItem(service: "com.appsandwich.ppt2rk", account: e)
        
        do {
            try keychainItem.savePassword(p)
        }
        catch {
            fatalError("Error saving password - \(error)")
        }
    }
    
    runApp(email: e, password: p, args: argsParser)
}
else if argsParser.hasArgumentOfType(.keychain) {
    
    // Load from keychain
    
    var passwordItems: [KeychainPasswordItem]? = nil
    
    do {
        passwordItems = try KeychainPasswordItem.passwordItems(forService: "com.appsandwich.ppt2rk")
    }
    catch {
        fatalError("Error fetching password items - \(error)")
    }
    
    guard let pws = passwordItems, pws.count > 0, let e = pws.first?.account else {
        printHelp()
        exitWithErrorCode(.noKeychainItems)
        exit(0) // Suppress compiler warning.
    }
    
    var p: String? = nil
    
    do {
        try p = pws.first?.readPassword()
    }
    catch {
        printHelp()
        exitWithErrorCode(.noKeychainItems)
    }
    
    guard let pass = p else {
        printHelp()
        exitWithErrorCode(.noKeychainItems)
        exit(0) // Suppress compiler warning.
    }
    
    runApp(email: e, password: pass, args: argsParser)
}
else {
    printHelp()
    exitWithErrorCode(.badArgument)
}




