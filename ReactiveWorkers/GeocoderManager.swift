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

class GeocoderManager {
    static func geocode(address: String) -> SignalProducer<CLLocation, NSError> {
        return SignalProducer {
            sink, disposable in
            println("Geocode for address : \(address)")
            CLGeocoder().geocodeAddressString(address) {
                placemarks, err in
                println("Geocode result for \(address) : \(placemarks), \(err)")
                if let error = err {
                    sendError(sink, error)
                } else if let location = (placemarks as? [CLPlacemark])?.first?.location {
                    sendNext(sink, location)
                } else {
                    sendError(sink, NSError(domain: kCLErrorDomain, code: CLError.LocationUnknown.rawValue, userInfo: nil))
                }
            }
        }
    }
}