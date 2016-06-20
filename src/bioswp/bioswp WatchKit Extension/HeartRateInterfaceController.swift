//
//  HeartRateInterfaceController.swift
//  bioswp
//
//  Created by Stephan Thordal Larsen on 16/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import WatchConnectivity

class HeartRateInterfaceContext : AnyObject {
    var instruction: String?
    var dataStorePath : String?
    var sampleDuration : Double?
    var completionClosure : () -> Void = {() -> Void in return}
}

class HeartRateInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate, WCSessionDelegate {
    
    // MARK: Outlets
    @IBOutlet var instructionLabel: WKInterfaceLabel!
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    
    // MARK: Private Variables
    private let healthStore = HKHealthStore()
    private let hearRateUnit = HKUnit(fromString: "count/min")
    
    private var workoutActive = false
    private var workoutSession : HKWorkoutSession?
    private var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    private var startDate : NSDate?
    private var endDate : NSDate?
    
    // MARK: Public Variables
    var localContext : HeartRateInterfaceContext?
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
   
    // MARK: Overrides
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        print("Awoke with context")
        localContext = context as? HeartRateInterfaceContext
    }

    override func willActivate() {
        super.willActivate()
        print("Will Activate")
        instructionLabel.setText(localContext?.instruction)
        
        guard HKHealthStore.isHealthDataAvailable() else {
            displayError("Health data not available")
            return
        }
        
        guard let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
            displayError("Cannot get quantitytype")
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorizationToShareTypes(nil, readTypes: dataTypes) { (success, error) ->  Void in
            if !success { self.displayError("Not authorized to share types") }
        }
        if let duration = localContext?.sampleDuration {
            startWorkout()
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(duration * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.stopWorkout()
                self.localContext?.completionClosure()
            }
        }
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
    
    // MARK: Helpers
    func displayError(errorMessage: String? = nil) {
        if let message = errorMessage {
            print(message)
        } else {
            print("undefined error")
        }
        
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        switch toState {
        case .Running:
            workoutDidStart(date)
        case .Ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        displayError("Workout session failed with error: \(error.localizedDescription)")
    }
    
    func workoutDidStart(date: NSDate) {
        // TODO: Start some animations
        if let query = getHeartRateStreamingQuery(date) {
            startDate = date
            healthStore.executeQuery(query)
        } else {
            displayError("Could not get heart rate streaming query")
        }
    }
    
    func workoutDidEnd(date: NSDate) {
        // TODO: When workout ends, save to injected NSURL
        if let query = getHeartRateStreamingQuery(date) {
            endDate = date
            healthStore.stopQuery(query)
            if let path = localContext?.dataStorePath {
                storeHeartRateData(startDate!, endDate: endDate!, location: path)
            }
            self.popToRootController()
        } else {
            displayError("Could not get heart rate streaming query")
        }
    }
    
    func startWorkout() {
        self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.Yoga,
                                              locationType: HKWorkoutSessionLocationType.Indoor)
        self.workoutSession?.delegate = self
        healthStore.startWorkoutSession(self.workoutSession!)
        self.workoutActive = true
    }
    
    func stopWorkout() {
        healthStore.endWorkoutSession(self.workoutSession!)
        self.workoutActive = false
    }
    
    func storeHeartRateData(startDate: NSDate, endDate: NSDate, location: String) {
        let heartRateType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        var heartRateArray = Array<Double>()
        self.healthStore
            .requestAuthorizationToShareTypes(nil, readTypes: [heartRateType], completion: {(success, error) -> Void in
                let sortByTime = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                let datePredicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: HKQueryOptions.None)
                let query = HKSampleQuery(sampleType: heartRateType,
                                            predicate: datePredicate,
                                            limit: 1000,
                                            sortDescriptors: [sortByTime],
                                            resultsHandler: {(query, results, error) in
                                                guard let results = results else { return }
                                                for sample in results {
                                                    let quantity = (sample as! HKQuantitySample).quantity
                                                    let heartRateUnit = HKUnit(fromString: "count/min")
                                                    heartRateArray.append(quantity.doubleValueForUnit(heartRateUnit))
                                                }
                                                if WCSession.isSupported() {
                                                    self.session = WCSession.defaultSession()
                                                    self.session!.sendMessage(
                                                        ["heartRateArray": heartRateArray, "location": location],
                                                        replyHandler: {(response) -> Void in
                                                            print("Succesful heart-rate msg to phone")
                                                        },
                                                        errorHandler: {(error) -> Void in
                                                            print("Unsuccesful heart-rate msg to phone")
                                                        })
                                                } else {
                                                    print("WCSession not supported")
                                                }
                                            })
                self.healthStore.executeQuery(query)
        })
    }
    
    func getHeartRateStreamingQuery(workoutStartDate: NSDate) -> HKQuery? {
        guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
            return nil
        }
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType,
                                                   predicate: nil,
                                                   anchor: anchor,
                                                   limit: Int(HKObjectQueryNoLimit))
                                                   {(query, sampleObjs, deletedObjs, newAnchor, error) -> Void in
                                                    guard let newAnchor = newAnchor else { return }
                                                    self.anchor = newAnchor
                                                    self.updateHeartRate(sampleObjs)
                                                   }
        heartRateQuery.updateHandler = {(query, sampleObjs, deletedObjs, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(sampleObjs)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        dispatch_async(dispatch_get_main_queue()) {
            guard let sample = heartRateSamples.first else { return }
            let value = sample.quantity.doubleValueForUnit(self.hearRateUnit)
            self.heartRateLabel.setText("\(value)")
            // TODO: Update some GUI with value
        }
    }
}
