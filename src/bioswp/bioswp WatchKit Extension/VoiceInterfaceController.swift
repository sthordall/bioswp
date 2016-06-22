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
        if let location = localContext?.dataStorePath {
            rec(location)
        }
    }
    
    func rec(toFile: String) {
        guard let duration = localContext?.sampleDuration else { return }
        if let recFileUrl = recFileURL(toFile) {
            self.presentAudioRecorderControllerWithOutputURL(
                recFileUrl,
                preset: WKAudioRecorderPreset.WideBandSpeech,
                options: [WKAudioRecorderControllerOptionsMaximumDurationKey: NSTimeInterval(duration)],
                completion: { (didSave, error) -> Void in
                    print("error: \(error)\n")
                    if didSave {
                        self.storeVoiceData(toFile, dataUrl: recFileUrl)
                        self.popController()
                    } else { self.popController() }
            })
        } else { self.popController() }
    }
    
    func recFileURL(fileName:String) -> NSURL? {
        if let container = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.io.sthordall.app.bioswp") {
            return container.URLByAppendingPathComponent(fileName, isDirectory: false)
        } else {
            return nil
        }
    }
    
    func storeVoiceData (location: String, dataUrl: NSURL) {
        if WCSession.isSupported() {
            self.session = WCSession.defaultSession()
            self.session!.transferFile(dataUrl, metadata: ["location": location])
        }
    }
}