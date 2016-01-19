//
//  Swizzle.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation

enum Swizzle: ErrorType {
    case Failed(method: String)
}

func swizzle(reciever: AnyClass, replace from: String, with to: String) throws {
    let originalSelector = Selector(from)
    let swizzledSelector = Selector(to)
    
    let originalMethod = class_getInstanceMethod(reciever, originalSelector)
    let swizzledMethod = class_getInstanceMethod(reciever, swizzledSelector)
    
    let didAddMethod = class_addMethod(reciever, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
    
    if didAddMethod {
        // class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        throw Swizzle.Failed(method: from)
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
