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
        let id: Int
        
        func start() -> SignalProducer<TaskResult, NSError> {
            return SignalProducer {
                sink, disposable in
                
                sendNext(sink, SleepTaskResult(message:"Start to sleep #\(self.id)"))
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                    Int64(self.timeInterval * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    sendNext(sink, SleepTaskResult(message:"Good Sleep #\(self.id)"))
                    sendCompleted(sink)
                }
            }
        }
    }
    
    public func sleep(timeInterval: Double = 2, id: Int = Int(rand()), priority: Priority = .Medium) -> SignalProducer<String, NSError> {
        return add(SleepTask(timeInterval: timeInterval, id: id), priority: priority)
            |> map { result in (result as! SleepTaskResult).message }
    }
}