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

public class GeocoderManager: TaskPool {
    
    struct GeocoderTaskResult: TaskResult {
        let location: CLLocation
    }
    
    struct GeocoderTask: Task {
        let address: String
        
        func start() -> SignalProducer<TaskResult, NSError> {
            return SignalProducer {
                sink, disposable in
                println("Geocode for address : \(self.address)")
                let geocoder = CLGeocoder()
                geocoder.geocodeAddressString(self.address) {
                    placemarks, err in
                    println("Geocode result for \(self.address) : \(placemarks), \(err)")
                    if let error = err {
                        sendError(sink, error)
                    } else if let location = (placemarks as? [CLPlacemark])?.first?.location {
                        sendNext(sink, GeocoderTaskResult(location: location))
                        sendCompleted(sink)
                    } else {
                        sendError(sink, NSError(domain: kCLErrorDomain, code: CLError.LocationUnknown.rawValue, userInfo: nil))
                    }
                }
            }
        }
    }
   
    public func geocode(address: String, priority: Priority = .Medium) -> SignalProducer<CLLocation, NSError> {
        return add(GeocoderTask(address: address), priority: priority)
            |> map { result in (result as! GeocoderTaskResult).location }
    }
}
