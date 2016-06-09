//
//  MoveInterfaceController.swift
//  bioswp
//
//  Created by Stephan Thordal Larsen on 09/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion

extension CMSensorDataList: SequenceType {
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}

class MoveInterfaceController: WKInterfaceController {
    
    // MARK: Constants
    
    let timerDuration = 5.0
    let timerInterval = 1.0
    let recorder = CMSensorRecorder()
    
    // MARK: Variables
    
    var elapsedTime = 0.0
    var moveTimer: NSTimer?
    var moveDate: NSDate?
    
     // MARK: Outlets

    @IBOutlet var instructionLabel: WKInterfaceLabel!
    @IBOutlet var countdownTimer: WKInterfaceTimer!
    @IBOutlet var startButton: WKInterfaceButton!
    
    // MARK: Actions
    
    @IBAction func startActivated() {
        startButton.setHidden(true)
        countdownTimer.setHidden(false)
        instructionLabel.setText("Move!")
        moveTimer = NSTimer.scheduledTimerWithTimeInterval(
            timerDuration,
            target: self,
            selector: #selector(MoveInterfaceController.timerDone),
            userInfo: nil,
            repeats: false)
        countdownTimer.setDate(NSDate(timeIntervalSinceNow: timerDuration))
        countdownTimer.start()
        if CMSensorRecorder.isAccelerometerRecordingAvailable() {
            moveDate = NSDate()
            recorder.recordAccelerometerForDuration(timerDuration)
        }
    }
    
    // MARK: Helpers
    
    func timerDone() {
        countdownTimer.setHidden(true)
        instructionLabel.setText("Great success!")
        
        let accelerometerData:CMSensorDataList = recorder.accelerometerDataFromDate(moveDate!, toDate: NSDate())!
        if let container = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.io.sthordall.app.bioswp") {
            let fileUrl = container.URLByAppendingPathComponent("movedata")
            print(fileUrl)
            for data in accelerometerData {
                print(data)
            }
        }
        self.popToRootController()
    }
    
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
