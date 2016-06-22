//
//  DynamicTimeWarpInterfaceController.swift
//  bioswp
//
//  Created by Stephan Thordal Larsen on 21/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

import WatchKit
import Foundation

class DynamicTimeWarpInterfaceContext {
    var testSampleSize : Int?
    var instruction : String?
}

class DynamicTimeWarpInterfaceController: WKInterfaceController {
    @IBOutlet var resultLabel: WKInterfaceLabel!
    @IBOutlet var instructionLabel: WKInterfaceLabel!
    
    var localContext : DynamicTimeWarpInterfaceContext?
    var dtwStart : NSDate?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        guard let localContext = context as? DynamicTimeWarpInterfaceContext else {return}
        instructionLabel.setText(localContext.instruction!)
        resultLabel.setText("Running DTW on \(localContext.testSampleSize!) sized vectors..")
        dtwStart = NSDate()
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(queue) {
            let dtw = DynamicTimeWarper()
            let testArr1 = (0...localContext.testSampleSize!).map {_ in drand48()}
            let testArr2 = (0...localContext.testSampleSize!).map {_ in drand48()}
            let distance = String(format: "%.2f", dtw.distance(testArr1, target: testArr2))
            let deltaTime = String(format: "%.2f", abs(self.dtwStart!.timeIntervalSinceNow))
            self.resultLabel.setText("Time: \(deltaTime)s\nDistance: \(distance)\nSize: \(localContext.testSampleSize!)")
        }
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
