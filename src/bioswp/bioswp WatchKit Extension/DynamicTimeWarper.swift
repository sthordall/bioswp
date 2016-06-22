//
//  DynamicTimeWarper.swift
//  bioswp
//
//  Created by Stephan Thordal Larsen on 17/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

import Foundation

class DynamicTimeWarper {
    func distance(source: Array<Double>, target: Array<Double>) -> Double {
        var DTW = Array(count: source.count,
                        repeatedValue: Array(count: target.count,
                                             repeatedValue: 0.0))
        for i in 1...(source.count-1) {
            DTW[i][0] = Double.infinity
        }
        for i in 1...(target.count-1) {
            DTW[0][i] = Double.infinity
        }
        DTW[0][0] = 0
        
        for i in 1...(source.count-1) {
            for j in 1...(target.count-1) {
                let cost = source[i].distanceTo(target[j])
                DTW[i][j] = cost + min(DTW[i-1][j], DTW[i][j-1], DTW[i-1][j-1])
            }
        }
        
        return DTW[source.count-1][target.count-1]
    }
    
}