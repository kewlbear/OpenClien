//
//  UIViewController+Stack.m
//  Clien
//
//  Created by 안창범 on 12. 11. 9..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "UIViewController+Stack.h"

@implementation UIViewController (Stack)

- (void)push:(UIViewController *)viewController {
    UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:viewController];
    controller.view.frame = CGRectOffset([UIScreen mainScreen].applicationFrame, self.view.frame.size.width, 0);
    [self.view.window addSubview:controller.view];
    [self addChildViewController:controller];
    [UIView animateWithDuration:.2 animations:^{
        controller.view.frame = [UIScreen mainScreen].applicationFrame;
    } completion:^(BOOL finished) {
        [controller didMoveToParentViewController:self];
    }];
}

- (void)setGestureRecognizer {
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:panGestureRecognizer];
}

- (void)pan:(UIPanGestureRecognizer*)panGestureRecognizer {
    NSLog(@"%s: %@", __func__, panGestureRecognizer);
    CGFloat x = [panGestureRecognizer translationInView:self.view].x;
    if (panGestureRecognizer.state == UIGestureRecognizerStateChanged && x > 0) {
        self.navigationController.view.frame = CGRectOffset([UIScreen mainScreen].applicationFrame, x, 0);
    } else {
        if (panGestureRecognizer.state == UIGestureRecognizerStateEnded
            && self.navigationController.view.frame.origin.x > 100) {
            [UIView animateWithDuration:.2 animations:^{
                self.navigationController.view.frame = CGRectOffset([UIScreen mainScreen].applicationFrame, self.view.frame.size.width, 0);
            } completion:^(BOOL finished) {
                [self.navigationController.view removeFromSuperview];
                [self removeFromParentViewController];
            }];
            return;
        }
        self.navigationController.view.frame = [UIScreen mainScreen].applicationFrame;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    NSLog(@"%s: %@ %@", __func__, gestureRecognizer, otherGestureRecognizer);
    return YES;
}

@end
