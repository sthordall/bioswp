//
//  DataContext.swift
//  bioswp
//
//  Created by Stephan Thordal Larsen on 21/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

class DataContext : AnyObject {
    var instruction: String?
    var dataStorePath : String?
    var sampleDuration : Double?
    var completionClosure : () -> Void = {() -> Void in return}
}