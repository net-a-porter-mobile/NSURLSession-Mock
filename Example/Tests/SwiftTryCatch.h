//
//  SwiftTryCatch.h
//  NSURLSession-Mock
//
//  Created by Kerr Miller on 16/03/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwiftTryCatch : NSObject

+ (void)tryBlock:(void (^)())block catchBlock:(void (^)(NSException *))catchBlock finallyBlock:(void (^)())finallyBlock;

@end
