//
//  UIViewController+Stack.h
//  Clien
//
//  Created by 안창범 on 12. 11. 9..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Stack) <UIGestureRecognizerDelegate>

- (void)push:(UIViewController*)viewController;
- (void)setGestureRecognizer;

@end
