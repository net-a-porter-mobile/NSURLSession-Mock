//
//  Logging.swift
//  Pods
//
//  Created by Sam Dean on 20/01/2016.
//
//

import Foundation

/**
 Wraps NSLog and makes sure we have a consistent marker in the console to filter by
 */
func Log(_ format: String) {
    NSLog("[NSURLSession-Mock] %@", format)
}
