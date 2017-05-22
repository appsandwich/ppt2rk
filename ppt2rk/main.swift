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

let runkeeperUploadQueue = RunkeeperActivityUploadQueue()

func exitApp() {
    semaphore.signal()
}

func exitWithErrorCode(_ code: ExitCode) {
    exit(code.rawValue)
}

func printHelp() {
    print("Usage: ppt2rk --email youremail@address.com --password yourpolarpassword")
}

func runApp(polarEmail: String, polarPassword: String, runkeeperEmail: String?, runkeeperPassword: String?, args: ArgsParser) {
    
    var runkeeperUserID: String? = nil
    
    if let arg = args.argumentForType(.download), let argValue = arg.value, let v = DownloadArgumentValue(rawValue: argValue), v == .runkeeper {
        
        guard let rke = runkeeperEmail, let rkp = runkeeperPassword else {
            exitWithErrorCode(.badArgument)
            return
        }
        
        Runkeeper.loginWithEmail(rke, password: rkp, handler: { (userID) in
            
            guard let u = userID else {
                print("Runkeeper login failed.")
                return
            }
            
            print("Logged in to Runkeeper as user ID \(u). Waiting for Polar workouts list...")
            
            runkeeperUserID = u
        })
    }
    
    
    Polar.loginWithEmail(polarEmail, password: polarPassword, handler: { (loggedIn) in
        
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
                else if let v = DownloadArgumentValue(rawValue: argValue), v == .runkeeper {
                    
                    // Runkeeper sync
                    
                    guard let rkUser = runkeeperUserID else {
                        print("Error: Runkeeper login failed or timed out.")
                        exitWithErrorCode(.loginFailed)
                        return
                    }
                    
                    print("Performing Runkeeper sync...")
                    
                    let months = ws.flatMap({ (workout) -> String? in
                        return workout.runkeeperMonth
                    })
                    
                    let uniqueMonths = Set(months)
                    
                    //print("\(uniqueMonths)")
                    
                    uniqueMonths.forEach({ (month) in
                        
                        Runkeeper.loadActivitiesForUserID(rkUser, month: month, handler: { (activities) in
                            
                            let workoutsForMonth = ws.filter({ (workout) -> Bool in
                                return workout.runkeeperMonth == month
                            })
                            
                            guard workoutsForMonth.count > 0 else {
                                print("Error: Something bad happened.")
                                exitWithErrorCode(.unknown)
                                return
                            }

                            
                            var activitiesForMonth: [RunkeeperActivity]
                            
                            if let afm = activities {
                                activitiesForMonth = afm
                            }
                            else {
                                print("No Runkeeper activities found for \(month).")
                                activitiesForMonth = []
                            }
                            
                            //print("\(a.count) Runkeeper activities found for \(month).")
                            
                            let polarWorkoutsToSync = workoutsForMonth.filter({ (workout) -> Bool in
                                return !activitiesForMonth.contains(where: { (activity) -> Bool in
                                    
                                    guard let day = workout.runkeeperDay else {
                                        return false
                                    }
                                    
                                    return activity.day == day
                                })
                            })
                            
                            if polarWorkoutsToSync.count > 0 {
                                
                                print("Runkeeper: \(month) is out of sync.")
                                
                                polarWorkoutsToSync.forEach({ (workout) in
                                    
                                    // REMOVE THIS
                                    //workout.id = "246351701"
                                    
                                    let dataHandler: (Data?) -> Void = { (gpxData) in
                                        
                                        guard let polarGPXData = gpxData else {
                                            return
                                        }
                                        
                                        print("\(workout) has data. Upload to Runkeeper!")
                                        
                                        runkeeperUploadQueue.enqueueGPXData(polarGPXData, workout: workout, handler: { (activityWithConvertedData) in
                                            
                                            guard let createdActivity = activityWithConvertedData else {
                                                return
                                            }
                                            
                                            print("Created Runkeeper activity with ID: \(createdActivity.id)")
                                        })
                                    }
                                    
                                    if let data = Cache.cachedGPXDataForFile(workout.id) {
                                       dataHandler(data)
                                    }
                                    else {
                                        Polar.exportGPXForWorkoutID(workout.id, handler: dataHandler)
                                    }
                                })
                            }
                        })
                    })
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

func downloadWorkout(_ workout: PolarWorkout, handler: @escaping (Data?) -> Void) {
    
    Polar.exportGPXForWorkoutID(workout.id, handler: { (gpxData) in
        
        guard let data = gpxData else {
            handler(nil)
            return
        }
        
        if let url = Cache.cacheGPXData(data, filename: workout.id) {
            print("GPX saved to \(url).")
            workout.markAsDownloaded()
        }
        
        handler(data)
    })
}

func downloadWorkouts( _ workouts: [PolarWorkout], showPromptWhenFinished: Bool) {
    
    guard workouts.count > 0 else {
        exitApp()
        return
    }
    
    
    let group = DispatchGroup()
    
    workouts.forEach { (workout) in
        
        group.enter()
        
        downloadWorkout(workout, handler: { (gpxData) in
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


let credentials = Credentials(argsParser)


// Polar

var polarEmail = credentials.polarEmail()
var polarPassword = credentials.polarPassword()

if polarEmail != nil && polarPassword == nil {
    
    print("Please enter your Polar password to continue: ")
    polarPassword = readLine()
    
    if let e = polarEmail, let p = polarPassword, argsParser.hasArgumentOfType(.keychain) {
        credentials.saveEmail(e, password: p, argumentType: .polarPassword)
    }
}


// Runkeeper

var rkEmail = credentials.runkeeperEmail()
var rkPassword = credentials.runkeeperPassword()

if rkEmail != nil && rkPassword == nil {
    
    print("Please enter your Runkeeper password to continue: ")
    rkPassword = readLine()
    
    if let e = rkEmail, let p = rkPassword, argsParser.hasArgumentOfType(.keychain) {
        credentials.saveEmail(e, password: p, argumentType: .runkeeperPassword)
    }
}


if let e = polarEmail, let p = polarPassword {
    runApp(polarEmail: e, polarPassword: p, runkeeperEmail: rkEmail, runkeeperPassword: rkPassword, args: argsParser)
}
else {
    printHelp()
    exitWithErrorCode(.badArgument)
}




