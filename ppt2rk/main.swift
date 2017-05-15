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
                
                if let dlArgValue = args.argumentForType(.download)?.value, let indexes = ArgsParser.DownloadArgumentValue.indexesForRawString(dlArgValue, numberOfItems: (workouts?.count)!) {
                    downloadWorkoutsAtIndexes(indexes, workouts: workouts!, showPromptWhenFinished: false)
                    
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
    
    guard workoutsToDownload.count > 0 else {
        exitApp()
        return
    }
    
    
    let group = DispatchGroup()
    
    workoutsToDownload.forEach { (workout) in
        
        group.enter()
        
        Polar.exportGPXForWorkoutID(workout.id, handler: { (gpxData) in
            
            guard let data = gpxData else {
                group.leave()
                return
            }
            
            if let url = Cache.cacheGPXData(data, filename: workout.id) {
                print("GPX saved to \(url).")
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

if argsParser.hasArgumentOfType(.email) && argsParser.hasArgumentOfType(.password) {
 
    var email = argsParser.argumentForType(.email)
    var password = argsParser.argumentForType(.password)
    
    if let e = email?.value, let p = password?.value {
        runApp(email: e, password: p, args: argsParser)
    }
    else {
        printHelp()
        exitWithErrorCode(.badArgument)
    }
}
else {
    printHelp()
    exitWithErrorCode(.badArgument)
}




