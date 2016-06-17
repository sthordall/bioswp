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

class HeartRateInterfaceContext : AnyObject {
    var instruction: String?
    var dataStorePath : String?
    var sampleDuration : Double?
    var completionClosure : () -> Void = {() -> Void in return}
}

class HeartRateInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    
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
   
    // MARK: Overrides
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        localContext = context as? HeartRateInterfaceContext
    }

    override func willActivate() {
        super.willActivate()
        instructionLabel.setText(localContext?.instruction)
        
        guard HKHealthStore.isHealthDataAvailable() else {
            displayError()
            return
        }
        
        guard let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
            displayError()
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorizationToShareTypes(nil, readTypes: dataTypes) { (success, error) ->  Void in
            if !success { self.displayError() }
        }
        if let duration = localContext?.sampleDuration {
            startWorkout()
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(duration * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.stopWorkout()
                self.localContext?.completionClosure()
                self.popToRootController()
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
        displayError(error.localizedDescription)
    }
    
    func workoutDidStart(date: NSDate) {
        // TODO: Start some animations
        if let query = getHeartRateStreamingQuery(date) {
            startDate = date
            healthStore.executeQuery(query)
        } else {
            displayError()
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
        } else {
            displayError()
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
        if let workout = self.workoutSession {
            healthStore.endWorkoutSession(workout)
        }
        self.workoutActive = false
    }
    
    func storeHeartRateData(startDate: NSDate, endDate: NSDate, location: String) {
        let heartRateType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        var heartRateArray = Array<Double>()
        self.healthStore
            .requestAuthorizationToShareTypes(nil, readTypes: [heartRateType], completion: {(success, error) -> Void in
                let sortByTime = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                let datePredicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: HKQueryOptions.None)
                let query = HKSampleQuery(sampleType: heartRateType, predicate: datePredicate, limit: 1000, sortDescriptors: [sortByTime], resultsHandler: {(query, results, error) in
                    guard let results = results else { return }
                    for sample in results {
                        let quantity = (sample as! HKQuantitySample).quantity
                        let heartRateUnit = HKUnit(fromString: "count/min")
                        heartRateArray.append(quantity.doubleValueForUnit(heartRateUnit))
                    }
                    do {
                        let documentsDir = try NSFileManager.defaultManager()
                                                            .URLForDirectory(.DocumentDirectory,
                                                                             inDomain: .UserDomainMask,
                                                                             appropriateForURL: nil,
                                                                             create: true)
                        
                        try heartRateArray.description.writeToURL(NSURL(string: location, relativeToURL: documentsDir)!,
                                                                  atomically: true,
                                                                  encoding: NSASCIIStringEncoding)
                    } catch {
                       self.displayError("Could not save data to \(location)")
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
