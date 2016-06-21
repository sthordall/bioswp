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

class MovementInterfaceContext : DataContext {}

class MovementInterfaceController : WKInterfaceController, WCSessionDelegate  {
    @IBOutlet var instructionLabel: WKInterfaceLabel!
    @IBOutlet var xLabel: WKInterfaceLabel!
    @IBOutlet var yLabel: WKInterfaceLabel!
    @IBOutlet var zLabel: WKInterfaceLabel!
    
    var localContext: MovementInterfaceContext?
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
}