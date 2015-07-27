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
}

