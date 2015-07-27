//
//  SleepManager.swift
//  ReactiveWorkers
//
//  Created by Julien DAUPHANT on 27/07/15.
//  Copyright (c) 2015 Julien Dauphant. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class SleepManager: TaskPool {
    
    struct SleepTaskResult: TaskResult {
        let message: String
    }
    
    struct SleepTask: Task {
        let timeInterval: Double
        
        func start() -> SignalProducer<TaskResult, NSError> {
            return SignalProducer {
                sink, disposable in
                println("Start to sleep")
                NSThread.sleepForTimeInterval(self.timeInterval)
                sendNext(sink, SleepTaskResult(message:"Good Sleep"))
            }
        }
    }
    
    public func sleep(timeInterval: Double = 2) -> SignalProducer<String, NSError> {
        return add(SleepTask(timeInterval: timeInterval))
            |> map { result in (result as! SleepTaskResult).message }
    }
}