//
//  MKSellBid.m
//  BitMarkets
//
//  Created by Steve Dekorte on 5/6/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "MKSellBid.h"
#import "MKSell.h"
#import "MKAcceptBidMsg.h"
#import "MKRejectBidMsg.h"
#import "MKRootNode.h"

@implementation MKSellBid

- (id)init
{
    self = [super init];
    
    self.nodeShouldSortChildren = @NO;
    //self.nodeSortChildrenKey = @"date";
    //self.nodeSortAccending = @YES;
    
    self.nodeViewClass = NavMirrorView.class;
    
    [self updateActions];
    
    return self;
}

- (void)update
{
    [self updateActions];
}

- (void)updateActions
{
    {
        BOOL enabled = self.runningWallet && !self.wasAccepted && !self.wasRejected;
        NavActionSlot *acceptSlot = [self.navMirror newActionSlotWithName:@"accept"];
        [acceptSlot setVisibleName:@"Accept Bid"];
        [acceptSlot setIsVisible:YES];
        [acceptSlot setIsActive:enabled];
        [acceptSlot setVerifyMessage:@"A Bitmarkets transaction requires the buyer to lock 2x the amount of the item and the seller to lock 1x the amount of the item in escrow. This ensures both parties are incentivized to faithfully complete the transaction.\n\nThese bitcoins cannot be spent by either party until both parties agree to release them either for payment or refund."];
    }
}

- (NSDate *)date
{
    return self.bidMsg.date;
}

// --- equality ---

- (MKBidMsg *)bidMsg
{
    return self.children.firstObject;
}
   
- (NSUInteger)hash
{
    return self.bidMsg.hash;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:MKSellBid.class])
    {
        MKSellBid *otherSellBid = object;
        BOOL isEqual = [self.bidMsg isEqual:otherSellBid.bidMsg];
        return isEqual;
    }
    
    return YES;
}

// --- UI ------------------------------

- (NSNumber *)nodeSuggestedWidth
{
    return @450;
}

- (NSString *)nodeTitle
{
    return [NSString stringWithFormat:@"Bid from %@", self.bidMsg.buyerAddress];
}

- (NSString *)nodeSubtitle
{
    return self.status;
}

// --- status --------------------

- (NSString *)status
{
    if (self.error)
    {
        return self.error;
    }
    if (self.acceptMsg)
    {
        return [NSString stringWithFormat:@"accepted %@", self.acceptMsg.dateString];
    }
    else if (self.rejectMsg)
    {
        return @"rejected";
    }
    
    return @"ready to accept...";
}

- (MKAcceptBidMsg *)acceptMsg
{
    return [self.children firstObjectOfClass:MKAcceptBidMsg.class];
}

- (MKRejectBidMsg *)rejectMsg
{
    return [self.children firstObjectOfClass:MKRejectBidMsg.class];
}

- (BOOL)wasAccepted
{
    return self.acceptMsg != nil;
}

- (BOOL)wasRejected
{
    return self.rejectMsg != nil;
}

- (NSString *)nodeNote
{
    if (self.wasAccepted)
    {
        return @"✓";
    }
    
    if (self.wasRejected)
    {
        return @"✗";
    }
    
    return nil;
}

- (MKSellBids *)sellBids
{
    return (MKSellBids *)self.nodeParent;
}

- (MKSell *)sell
{
    return [self firstInParentChainOfClass:MKSell.class];
}

- (void)accept
{
    MKAcceptBidMsg *msg = [[MKAcceptBidMsg alloc] init];
    [msg copyThreadFrom:self.bidMsg];
    
    if ([msg send])
    {
        [self addChild:msg];
        [self updateActions];
        [self.sell write];
    }
    
    [self.sellBids rejectUnacceptedBids];
}

- (void)reject
{
    MKRejectBidMsg *msg = [[MKRejectBidMsg alloc] init];
    [msg copyThreadFrom:self.bidMsg];
    
    if ([msg send])
    {
        [self addChild:msg];
        [self updateActions];
        [self.sell write];
    }
}

- (BOOL)nodeShouldIndent
{
    return NO;
}

@end
