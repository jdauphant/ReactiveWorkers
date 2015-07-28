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
        
        addressResult.start(next: { result in
            self.textView.text = "\(result)\n\(self.textView.text)"
            })
        
    }
    
    @IBAction func runTests() {
        self.textView.text = ""
        testSleepManager()
    }
    
    
    func addText(text: String) {
        println("\(NSDate())\(text)")
        dispatch_async(dispatch_get_main_queue()) {
            self.textView.text = "\(self.textView.text)\(NSDate()) \(text)\n"
        }
    }

    
    func testSleepManager() {
        let sleepManager = SleepManager()
        
        let signal: SignalProducer<Int, NSError> = SignalProducer {
            sink, disposable in
            var count = 0
            NSTimer.schedule(repeatInterval: 0.5) { timer in
                sendNext(sink, count++)
                if count >= 12 {
                    timer.invalidate()
                    sendCompleted(sink)
                }
            }
        }
        
        signal
            |> flatMap(.Merge) {
                id in
                return sleepManager.sleep(timeInterval: 2, id: id)
                    |> on(started: { self.addText("task #\(id) in queue") }, completed: { self.addText("task #\(id) completed") })
            }
            |> start(next: addText)
    }
}

