//
//  MoveInfoInterfaceController.swift
//  bioswp
//
//  Created by Stephan Thordal Larsen on 09/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion

class MoveInfoInterfaceController: WKInterfaceController {

    @IBOutlet var moveInfoTable: WKInterfaceTable!
    var moveDataSource: [(Double, Double, Double)] = []
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        if let moveData = context as? CMSensorDataList {
            for data in moveData {
                moveDataSource.append((data.x, data.y, data.z))
            }
        }
        loadMoveTableData()
    }
    
    private func loadMoveTableData() {
        moveInfoTable.setNumberOfRows(moveDataSource.count, withRowType: "MoveInfoRowController")
        for (index, data) in moveDataSource.enumerate() {
            let row = moveInfoTable.rowControllerAtIndex(index) as! MoveInfoRowController
            row.x.setText("\(data.0)")
            row.y.setText("\(data.1)")
            row.z.setText("\(data.2)")
        }
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
