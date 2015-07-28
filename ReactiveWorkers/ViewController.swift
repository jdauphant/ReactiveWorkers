//
//  ViewController.swift
//  ReactiveWorkers
//
//  Created by Julien DAUPHANT on 27/07/15.
//  Copyright (c) 2015 Julien Dauphant. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ViewController: UIViewController {
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var textView: UITextView!
    private let geocodingManager = GeocoderManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        let addressStrings = textField.rac_signalForControlEvents(UIControlEvents.EditingDidEndOnExit).toSignalProducer()
            |> map { sender in self.textField.text }
        
        let addressResult = addressStrings
            |> flatMap(.Latest) { address in
                return self.geocodingManager.geocode(address)
            }
            |> observeOn(UIScheduler())
            |> start(next: { result in
                self.textView.text = "\(result)\n\(self.textView.text)"
            })
        
    }
    
    func addText(text: String) {
        println("\(NSDate())\(text)")
        dispatch_async(dispatch_get_main_queue()) {
            self.textView.text = "\(self.textView.text)\(NSDate()) \(text)\n"
        }
    }
    
    @IBAction func testPoolScheduler() {
        self.textView.text = ""
        let sleepManager = SleepManager()
        
        let signal: SignalProducer<Int, NSError> = SignalProducer {
            sink, disposable in
            var count = 0
            NSTimer.schedule(repeatInterval: 0.5) { timer in
                if count>=10 {
                    timer.invalidate()
                }
                sendNext(sink, count++)
            }
        }
        
        let scheduler = PoolScheduler(maxConcurrentActions: 3)
        
        signal
            |> flatMap(.Merge) {
                id in
                return sleepManager.sleep()
                    |> startOn(scheduler)
                    |> on(started: { self.addText("task #\(id) started") }, completed: { self.addText("task #\(id) completed") })
            }
            |> start(next: addText)
    }
    
    
    @IBAction func testPriorityScheduler() {
        self.textView.text = ""
        let sleepManager = SleepManager()
        let scheduler = PriorizedScheduler(maxConcurrentActions: 2)
        
        let signal: SignalProducer<(Int, PriorizedScheduler.Priority), NSError> = SignalProducer {
            sink, disposable in
            var count = 0
            NSTimer.schedule(repeatInterval: 1) { timer in
                if count>=15 {
                    timer.invalidate()
                }
                
                let priority: PriorizedScheduler.Priority
                if count%2 == 0 {
                    priority = .Low
                } else if count%3 == 0 {
                    priority = .High
                } else {
                    priority = .Medium
                }
                sendNext(sink, (count++,priority))
            }
        }
        
        signal
            |> flatMap(.Merge) {
                id, priority in
                return sleepManager.sleep(timeInterval: 2)
                    |> startOn(scheduler.withPriority(priority))
                    |> on(started: { self.addText("task #\(id) \(priority) started") }, completed: { self.addText("task #\(id) \(priority) completed") })
            }
            |> start(next: addText)
        
    }
}

