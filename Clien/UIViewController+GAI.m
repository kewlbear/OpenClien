//
//  UIViewController+GAI.m
//  Clien
//
//  Created by 안창범 on 2013. 11. 12..
//  Copyright (c) 2013년 안창범. All rights reserved.
//

#import "UIViewController+GAI.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation UIViewController (GAI)

- (void)sendHitWithScreenName:(NSString *)screenName {
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

@end
