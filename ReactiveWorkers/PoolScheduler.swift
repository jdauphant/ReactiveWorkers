//
//  PoolScheduler.swift
//  ReactiveWorkers
//
//  Created by Julien DAUPHANT on 27/07/15.
//  Copyright (c) 2015 Julien Dauphant. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class PoolScheduler: SchedulerType {
    static let DEFAULT_MAX_CONCURRENT_ACTIONS = 3
    
    let maxConcurrentActions: Int
    private var currentConcurrentActions  = 0
    private var pendingActions: [(action: () -> (), disposable: SimpleDisposable)] = []
    
    private let concurrentQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
    private let serialQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
 
    init(maxConcurrentActions: Int = DEFAULT_MAX_CONCURRENT_ACTIONS) {
        self.maxConcurrentActions = maxConcurrentActions
    }
    
    public func schedule(action: () -> ()) -> Disposable? {
        let disposable = SimpleDisposable()
        dispatch_async(self.serialQueue) {
            if self.currentConcurrentActions < self.maxConcurrentActions {
                self.currentConcurrentActions++
                self.startAction(action, disposable: disposable)
            } else {
                self.pendingActions.append(action: action, disposable: disposable)
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
            if self.pendingActions.isEmpty == false {
                let (action,disposable) = self.pendingActions.removeAtIndex(0)
                 self.startAction(action, disposable: disposable)
            } else {
                self.currentConcurrentActions--
            }
        }
    }
}