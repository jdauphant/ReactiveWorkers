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
    
    private let scheduler = PoolScheduler(maxConcurrentActions: 3)
    
    public func geocode(address: String) -> SignalProducer<CLLocation, NSError> {
        return SignalProducer { sink, disposable in
            let semaphore = dispatch_semaphore_create(0)
            CLGeocoder().geocodeAddressString(address) { placemarks, err in
                if let error = err {
                    sendError(sink, error)
                } else if let location = (placemarks as? [CLPlacemark])?.first?.location {
                    sendNext(sink, location)
                    sendCompleted(sink)
                } else {
                    sendError(sink, NSError(domain: kCLErrorDomain, code: CLError.LocationUnknown.rawValue, userInfo: nil))
                }
                dispatch_semaphore_signal(semaphore)
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        } |> startOn(scheduler)
    }
}