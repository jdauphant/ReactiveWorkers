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
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var searchButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        let addressStrings = searchButton.rac_signalForControlEvents(.TouchUpInside).toSignalProducer()
            |> map { sender in self.textField.text }
        
        let addressResult = addressStrings
            |> flatMap(.Latest) { address in
                return GeocoderManager.geocode(address)
            }
            |> observeOn(UIScheduler())
        
        addressResult.start(next: { result in
            self.textView.text = "\(result)\n\(self.textView.text)"
            })
        
        
    }
}

