//
//  PoolScheduler.swift
//  ReactiveWorkers
//
//  Created by Julien DAUPHANT on 27/07/15.
//  Copyright (c) 2015 Julien Dauphant. All rights reserved.
//

import Foundation
import ReactiveCocoa

public protocol TaskResult {
    
}

public protocol Task {
    func start() -> SignalProducer<TaskResult, NSError>
}

public class TaskPool {
    static let DEFAULT_MAX_CONCURRENT_TASKS = 3
    
    let maxConcurrentTasks: Int
    private var currentConcurrentTasks  = 0
    private var pendingTasks: [(task: Task, sink: SinkOf<Event<TaskResult, NSError>>, disposable: CompositeDisposable)] = []
    
    private let dispatchQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
    private let serialQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
 
    init(maxConcurrentTasks: Int = DEFAULT_MAX_CONCURRENT_TASKS) {
        self.maxConcurrentTasks = maxConcurrentTasks
    }
    
    func add(task: Task) -> SignalProducer<TaskResult, NSError> {
        return SignalProducer {
            sink, disposable in

            dispatch_async(self.serialQueue) {
                if self.currentConcurrentTasks < self.maxConcurrentTasks {
                    self.currentConcurrentTasks++
                    task.start()
                       |> start( next: { result in
                        sendNext(sink, result)
                        sendCompleted(sink)
                        self.checkPendingTasks()
                    })
                } else {
                    self.pendingTasks.append(task: task, sink: sink, disposable: disposable)
                    println("\(NSDate()) totalPendingTasks=\(self.pendingTasks.count)")
                }
            }
        }
    }
    
    private func checkPendingTasks() {
        dispatch_async(serialQueue) {
            if self.pendingTasks.isEmpty == false {
                let (task,sink,disposable) = self.pendingTasks.removeAtIndex(0)
                if disposable.disposed == false {
                    task.start()
                        |> start( next: { result in
                            sendNext(sink, result)
                            sendCompleted(sink)
                            self.checkPendingTasks()
                        })
                }
            } else {
                self.currentConcurrentTasks--
            }
        }
    }
    
}