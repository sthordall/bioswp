//
//  InterfaceController.swift
//  bioswp WatchKit Extension
//
//  Created by Stephan Thordal Larsen on 09/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion


class MainInterfaceController: WKInterfaceController {
    // MARK: Constants
    
    // MARK: Outlets
    
    
    // MARK: Actions
    
    @IBAction func movementButtonTapped() {
        let context = MovementInterfaceContext()
        context.instruction = "Sampling Movement"
        context.dataStorePath = "Movement_sample_\(NSTimeIntervalSince1970).data"
        context.sampleDuration = 10.0
        context.completionClosure = {() -> Void in print("Done")}
        self.pushControllerWithName("movementScene", context: context)
    }
    
    @IBAction func voiceButtonTapped() {
        let context = VoiceInterfaceContext()
        context.instruction = "Sampling Voice"
        context.dataStorePath = "Voice_sample_\(NSTimeIntervalSince1970).mp4"
        context.sampleDuration = 10.0
        context.completionClosure = {() -> Void in print("Done")}
        self.pushControllerWithName("voiceScene", context: context)
    }
    
    @IBAction func heartRateButtonTapped() {
        let context = HeartRateInterfaceContext()
        context.instruction = "Sampling Heart"
        context.dataStorePath = "HeartRate_sample_\(NSTimeIntervalSince1970).data"
        context.sampleDuration = 100.0
        context.completionClosure = {() -> Void in print("Done")}
        self.pushControllerWithName("heartRateScene", context: context)
     }
  
    // MARK: Helpers
   
   
    // MARK: Overrides
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
    }

}
