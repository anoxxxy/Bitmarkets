//
//  MKCancelMsg.h
//  BitMarkets
//
//  Created by Steve Dekorte on 6/10/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "MKLockMsg.h"

@interface MKCancelMsg : MKLockMsg

- (void)broadcast;

@end
