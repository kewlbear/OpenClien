//
//  UIViewController+Stack.m
//  Clien
//
//  Created by 안창범 on 12. 11. 9..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "UIViewController+Stack.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIViewController (Stack)

- (void)push:(UIViewController *)viewController {
    [self.navigationController pushViewController:viewController animated:YES];
    return;
    
    UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:viewController];
    controller.view.frame = CGRectOffset([UIScreen mainScreen].applicationFrame, self.view.frame.size.width, 0);
    CALayer* layer = controller.view.layer;
    layer.shadowOffset = CGSizeMake(-3, 0);
    layer.shadowOpacity = .5;
    [self.view.window.rootViewController addChildViewController:controller];
    [controller viewWillAppear:YES];
    [self.view.window.rootViewController.view addSubview:controller.view];
    [UIView animateWithDuration:.2 animations:^{
        controller.view.frame = [UIScreen mainScreen].applicationFrame;
    } completion:^(BOOL finished) {
        [controller viewDidAppear:YES];
        [controller didMoveToParentViewController:self.view.window.rootViewController];
    }];
}

- (void)setGestureRecognizer {
    UISwipeGestureRecognizer* swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    swipeGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:swipeGestureRecognizer];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        panGestureRecognizer.delegate = self;
        [self.view addGestureRecognizer:panGestureRecognizer];
    }
}

- (void)swipe:(UISwipeGestureRecognizer*)swipeGestureRecognizer {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)pan:(UIPanGestureRecognizer*)panGestureRecognizer {
//    NSLog(@"%s: %@", __func__, panGestureRecognizer);
    CGPoint translation = [panGestureRecognizer translationInView:self.view];
//    if (panGestureRecognizer.state == UIGestureRecognizerStateChanged && translation.x > 0) {
//        self.navigationController.view.frame = CGRectOffset([UIScreen mainScreen].applicationFrame, translation.x, 0);
//    } else {
//        if (panGestureRecognizer.state == UIGestureRecognizerStateEnded
//            && self.navigationController.view.frame.origin.x > 100) {
//            [self.navigationController willMoveToParentViewController:nil];
//            [UIView animateWithDuration:.2 animations:^{
//                self.navigationController.view.frame = CGRectOffset([UIScreen mainScreen].applicationFrame, self.view.frame.size.width, 0);
//            } completion:^(BOOL finished) {
//                [self.navigationController.view removeFromSuperview];
//                [self.navigationController removeFromParentViewController];
//            }];
//            return;
//        }
//        self.navigationController.view.frame = [UIScreen mainScreen].applicationFrame;
//    }
    if (YES || self.toolbarItems) {
        if (fabs(translation.y) > 10) {
            BOOL hidden = translation.y < 0;
            if (self.toolbarItems) {
                [self.navigationController setToolbarHidden:hidden animated:YES];
            }
            [self.navigationController setNavigationBarHidden:hidden animated:YES];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//    NSLog(@"%s: %@ %@", __func__, gestureRecognizer, otherGestureRecognizer);
    return YES;
}

- (UISwipeGestureRecognizer*)swipeGestureRecognizer {
    for (UIGestureRecognizer* r in self.view.gestureRecognizers) {
        if ([r isKindOfClass:[UISwipeGestureRecognizer class]]) {
            return (UISwipeGestureRecognizer*) r;
        }
    }
    return nil;
}

@end
