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

class HeartRateInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    
    // MARK:
    let healthStore = HKHealthStore()
    let hearRateUnit = HKUnit(fromString: "count/min")
    
    var workoutActive = false
    var workoutSession : HKWorkoutSession?
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    // MARK: Overrides
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }

    override func willActivate() {
        super.willActivate()
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
            healthStore.executeQuery(query)
        } else {
            displayError()
        }
    }
    
    func workoutDidEnd(date: NSDate) {
        // TODO: When workout ends, save to injected NSURL
        if let query = getHeartRateStreamingQuery(date) {
            healthStore.stopQuery(query)
        } else {
            displayError()
        }
    }

    func startWorkout() {
        self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.Yoga,
                                              locationType: HKWorkoutSessionLocationType.Indoor)
        self.workoutSession?.delegate = self
        healthStore.startWorkoutSession(self.workoutSession!)
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
            // TODO: Update some GUI with value
        }
    }
}
