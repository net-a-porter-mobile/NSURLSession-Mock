//
//  SwiftTryCatch.h
//  NSURLSession-Mock
//
//  Created by Kerr Miller on 16/03/2016.
//  Copyright © 2016 YOOX NET-A-PORTER. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwiftTryCatch : NSObject

+ (void)tryBlock:(void (^)(void))block catchBlock:(void (^)(NSException *))catchBlock finallyBlock:(void (^)(void))finallyBlock;

@end
