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
    
    let authRecFileName = "authrec.mp4"
    
    // MARK: Outlets
    
    
    // MARK: Actions
    
    @IBAction func enrollButtonActivated() {
        if let recFileUrl = recFileURL(authRecFileName) {
            self.presentAudioRecorderControllerWithOutputURL(
                recFileUrl,
                preset: WKAudioRecorderPreset.HighQualityAudio,
                options: nil,
                completion: { (didSave, error) -> Void in
                    print("error: \(error)\n")
                    if didSave {
                        self.pushControllerWithName("moveScene", context: nil)
                    }
                })
        } 
    }
    @IBAction func playButtonActivated() {
        if let playFileUrl = recFileURL(authRecFileName) {
            self.presentMediaPlayerControllerWithURL(
                playFileUrl,
                options: nil,
                completion: { (didPlay, endTime, error) -> Void in
                    print("error: \(error)\n")
                })
        }
    }
    
    // MARK: Helpers
    
    func recFileURL(fileName:String) -> NSURL? {
        if let container = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.io.sthordall.app.bioswp") {
            return container.URLByAppendingPathComponent(fileName, isDirectory: false)
        } else {
            return nil
        }
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
