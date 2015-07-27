//
//  SleepManager.swift
//  ReactiveWorkers
//
//  Created by Julien DAUPHANT on 27/07/15.
//  Copyright (c) 2015 Julien Dauphant. All rights reserved.
//

import Foundation

//
//  SleepManager.swift
//  ReactiveWorkers
//
//  Created by Julien DAUPHANT on 27/07/15.
//  Copyright (c) 2015 Julien Dauphant. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class SleepManager {

    private let scheduler = PoolScheduler(maxConcurrentActions: 3)
    
    public func sleep(timeInterval: Double = 2) -> SignalProducer<String, NSError> {
        return SignalProducer {
            sink, disposable in
            println("Start to sleep")
            NSThread.sleepForTimeInterval(timeInterval)
            sendNext(sink, "Well Sleep")
            sendCompleted(sink)
        } |> startOn(scheduler)
    }
}