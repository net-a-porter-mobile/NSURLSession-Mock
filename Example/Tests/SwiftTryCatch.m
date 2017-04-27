//
//  SwiftTryCatch.m
//  NSURLSession-Mock
//
//  Created by Kerr Miller on 16/03/2016.
//  Copyright © 2016 YOOX NET-A-PORTER. All rights reserved.
//

#import "SwiftTryCatch.h"

@implementation SwiftTryCatch

+ (void)tryBlock:(void (^)())block catchBlock:(void (^)(NSException *))catchBlock finallyBlock:(void (^)())finallyBlock {
    @try {
        block ? block() : nil;
    }
    @catch (NSException *exception) {
        catchBlock ? catchBlock(exception) : nil;
    }
    @finally {
        finallyBlock ? finallyBlock() : nil;
    }
}

@end
