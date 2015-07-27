//
//  GeocoderManager.swift
//  ReactiveWorkers
//
//  Created by Julien DAUPHANT on 27/07/15.
//  Copyright (c) 2015 Julien Dauphant. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreLocation

public class GeocoderManager {
    
    static let DEFAULT_MAX_CONCURRENT_ACTIONS = 3
    
    let maxConcurrentActions: Int
    private var currentConcurrentActions  = 0

    private let dispatchQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
    
    init(maxConcurrentActions: Int = DEFAULT_MAX_CONCURRENT_ACTIONS) {
        self.maxConcurrentActions = maxConcurrentActions
    }
    
    public func geocode(address: String) -> SignalProducer<CLLocation, NSError> {
        if currentConcurrentActions < maxConcurrentActions { // not Thread-Safe
            currentConcurrentActions++
            return SignalProducer {
                sink, disposable in
                println("Geocode for address : \(address)")
                dispatch_async(self.dispatchQueue) {
                    CLGeocoder().geocodeAddressString(address) {
                        placemarks, err in
                        if let error = err {
                            sendError(sink, error)
                        } else if let location = (placemarks as? [CLPlacemark])?.first?.location {
                            sendNext(sink, location)
                        } else {
                            sendError(sink, NSError(domain: kCLErrorDomain, code: CLError.LocationUnknown.rawValue, userInfo: nil))
                        }
                        self.currentConcurrentActions--
                    }
                }
            }
        } else {
            return SignalProducer {
                sink, disposable in
                    println("Too much tasks")
                    sendError(sink, NSError())
            }
        }
    }
}