//
//  VoiceInterfaceController.swift
//  bioswp
//
//  Created by Stephan Thordal Larsen on 21/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class VoiceInterfaceContext : DataContext {}

class VoiceInterfaceController : WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet var instructionLabel: WKInterfaceLabel!
    
    var localContext: VoiceInterfaceContext?
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
        localContext = context as? VoiceInterfaceContext
        instructionLabel.setText(localContext?.instruction)
        
    }
}