//
//  PoolScheduler.swift
//  ReactiveWorkers
//
//  Created by Julien DAUPHANT on 27/07/15.
//  Copyright (c) 2015 Julien Dauphant. All rights reserved.
//

import Foundation
import ReactiveCocoa
import PriorityQueue

public protocol TaskResult {
    
}

public protocol Task {
    func start() -> SignalProducer<TaskResult, NSError>
}

public class TaskPool {
    static let DEFAULT_MAX_CONCURRENT_TASKS = 3
    
    public enum Priority: Int, Printable {
        case High = 1, Medium, Low
        public var description: String {
            switch self {
                case .Low: return "Low"
                case .Medium: return "Medium"
                case .High: return "High"
            }
        }
    }
    
    let maxConcurrentTasks: Int
    private var currentConcurrentTasks  = 0
    private var pendingTasks = PriorityQueue<(
            priority: Priority,
            task: Task,
            sink: SinkOf<Event<TaskResult, NSError>>,
            disposable: CompositeDisposable
        )>( { t1, t2 in t1.priority.rawValue < t2.priority.rawValue } )
    
    private let concurrentQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
    private let serialQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
 
    init(maxConcurrentTasks: Int = DEFAULT_MAX_CONCURRENT_TASKS) {
        self.maxConcurrentTasks = maxConcurrentTasks
    }
    
    func add(task: Task, priority: Priority) -> SignalProducer<TaskResult, NSError> {
        return SignalProducer {
            sink, disposable in

            dispatch_async(self.serialQueue) {
                if self.currentConcurrentTasks < self.maxConcurrentTasks {
                    self.currentConcurrentTasks++
                    self.startTask(task, sink:sink, disposable: disposable)
                } else {
                    self.pendingTasks.push(priority: priority, task: task, sink: sink, disposable: disposable)
                    println("\(NSDate()) totalPendingTasks=\(self.pendingTasks.count)")
                }
            }
        }
    }
    
    
    private func startTask(task: Task, sink: SinkOf<Event<TaskResult, NSError>>, disposable: Disposable) {
        if disposable.disposed == false {
            dispatch_async(concurrentQueue) {
                task.start()
                    |> start(
                        next: { result in
                            sendNext(sink, result)
                        }, completed: {
                            sendCompleted(sink)
                            self.checkPendingTasks()
                        }, error: { error in
                            sendError(sink, error)
                            self.checkPendingTasks()
                        }, interrupted: {
                            sendInterrupted(sink)
                            self.checkPendingTasks()
                        })
            }
        } else {
            sendInterrupted(sink)
            self.checkPendingTasks()
        }
    }
    
    private func checkPendingTasks() {
        dispatch_async(serialQueue) {
            if let (priority, task,sink,disposable) = self.pendingTasks.pop() {
                self.startTask(task, sink:sink, disposable: disposable)
            } else {
                self.currentConcurrentTasks--
            }
        }
    }
    
}