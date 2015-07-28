//
//  PrioritizedPoolScheduler.swift
//  ReactiveWorkers
//
//  Created by Julien DAUPHANT on 28/07/15.
//  Copyright (c) 2015 Julien Dauphant. All rights reserved.
//

import Foundation
import ReactiveCocoa
import PriorityQueue

public class PriorizedScheduler: SchedulerType {
    static let DEFAULT_MAX_CONCURRENT_ACTIONS = 3
    
    public enum Priority: Int, Printable {
        case Low, Medium, High
        public var description: String {
            switch self {
                case .Low: return "Low"
                case .Medium: return "Medium"
                case .High: return "High"
            }
        }
    }
    
    private let priority: Priority
    private let implementation: PriorizedImplementationScheduler
    
    private init(priority: Priority, implementation: PriorizedImplementationScheduler) {
        self.priority = priority
        self.implementation = implementation
    }
    
    public convenience init(maxConcurrentActions: Int = DEFAULT_MAX_CONCURRENT_ACTIONS){
        self.init(
            priority: .Medium,
            implementation: PriorizedImplementationScheduler(maxConcurrentActions: maxConcurrentActions)
        )
    }
    
    public func schedule(action: () -> ()) -> Disposable? {
        return implementation.schedule(priority)(action: action)
    }
    
    public func withPriority(priority: Priority) -> PriorizedScheduler {
        return PriorizedScheduler(priority: priority, implementation: implementation)
    }
}

private class PriorizedImplementationScheduler {
    
    let maxConcurrentActions: Int
    private var currentConcurrentActions  = 0
    private var pendingActions = PriorityQueue<(
            priority: PriorizedScheduler.Priority,
            action: () -> (),
            disposable: SimpleDisposable
        )>( { t1, t2 in t1.priority.rawValue < t2.priority.rawValue } )
    
    private let concurrentQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
    private let serialQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
    
    init(maxConcurrentActions: Int) {
        self.maxConcurrentActions = maxConcurrentActions
    }
    
    func schedule(priority: PriorizedScheduler.Priority)(action: () -> ()) -> Disposable? {
        let disposable = SimpleDisposable()
        dispatch_async(self.serialQueue) {
            if self.currentConcurrentActions < self.maxConcurrentActions {
                self.currentConcurrentActions++
                self.startAction(action, disposable: disposable)
            } else {
                self.pendingActions.push(priority: priority, action: action, disposable: disposable)
                println("\(NSDate()) totalPendingActions=\(self.pendingActions.count)")
            }
        }
        return disposable
    }
    
    private func startAction(action: () -> (), disposable: Disposable) {
        dispatch_async(self.concurrentQueue) {
            if disposable.disposed == false {
                action()
            }
            self.checkPendingActions()
        }
    }
    
    private func checkPendingActions() {
        dispatch_async(serialQueue) {
            if let (p, action,disposable) = self.pendingActions.pop() {
                self.startAction(action, disposable: disposable)
            } else {
                self.currentConcurrentActions--
            }
        }
    }
}