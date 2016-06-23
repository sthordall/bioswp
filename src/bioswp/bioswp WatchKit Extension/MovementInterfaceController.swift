//
//  MovementInterfaceController.swift
//  bioswp
//
//  Created by Stephan Thordal Larsen on 21/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity
import CoreMotion

class MovementInterfaceContext : DataContext {}

class MovementInterfaceController : WKInterfaceController, WCSessionDelegate  {
    @IBOutlet var instructionLabel: WKInterfaceLabel!
    @IBOutlet var xLabel: WKInterfaceLabel!
    @IBOutlet var yLabel: WKInterfaceLabel!
    @IBOutlet var zLabel: WKInterfaceLabel!
    
    let motionManager = CMMotionManager()
    
    var localContext: MovementInterfaceContext?
    var measuredDataX: Array<Double> = []
    var measuredDataY: Array<Double> = []
    var measuredDataZ: Array<Double> = []
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        localContext = context as? MovementInterfaceContext
        instructionLabel.setText(localContext?.instruction)
    }
    
    override func willActivate() {
        motionManager.accelerometerUpdateInterval = 0.1
        if motionManager.accelerometerAvailable {
            let accelerometerHandler:CMAccelerometerHandler = {
                (data: CMAccelerometerData?, error:NSError?) -> Void in
                if let data = data {
                    self.xLabel.setText(String(format: "%.2f", data.acceleration.x))
                    self.yLabel.setText(String(format: "%.2f", data.acceleration.y))
                    self.zLabel.setText(String(format: "%.2f", data.acceleration.z))
                    self.measuredDataX.append(data.acceleration.x)
                    self.measuredDataY.append(data.acceleration.y)
                    self.measuredDataZ.append(data.acceleration.z)
                }
                if let error = error {
                    print(error.localizedDescription)
                }
                
            }
            if let duration = localContext?.sampleDuration {
                motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: accelerometerHandler)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(duration * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                    self.motionManager.stopAccelerometerUpdates()
                    if let location = self.localContext?.dataStorePath {
                        self.storeAccelerometerData(location,
                                                    dataX: self.measuredDataX,
                                                    dataY: self.measuredDataY,
                                                    dataZ: self.measuredDataZ)
                    }
                }
             }
       }
    }
    
    func storeAccelerometerData(location:String, dataX: Array<Double>, dataY: Array<Double>, dataZ: Array<Double>) {
        if WCSession.isSupported() {
            self.session = WCSession.defaultSession()
            let message = ["accelerometerArrayX": dataX,
                           "accelerometerArrayY": dataY,
                           "accelerometerArrayZ": dataZ,
                           "location": location]
            self.session!.sendMessage(message as! [String : AnyObject],
                                      replyHandler: {(response) -> Void in
                                        print("Succesful accelerometer msg to phone")
                                        self.localContext?.completionClosure()
                                        self.popController()
                                      },
                                      errorHandler: {(error) -> Void in
                                        print("Un-succesful accelerometer msg to phone")
                                        self.localContext?.completionClosure()
                                        self.popController()
                                      }
            )
        }
    }
}