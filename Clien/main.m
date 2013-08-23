//
//  main.m
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int (*originalWrite)(void*, const char*, int);

int filteringWrite(void* cookie, const char* buf, int nbyte)
{
    if (strcmp(buf, "AssertMacros: queueEntry,  file: /SourceCache/IOKitUser/IOKitUser-920.1.11/hid.subproj/IOHIDEventQueue.c, line: 512\n")) {
        return originalWrite(cookie, buf, nbyte);
    }
    return nbyte;
}

int main(int argc, char *argv[])
{
    if ([[UIDevice currentDevice].systemVersion isEqualToString:@"7.0"]) {
        originalWrite = stderr->_write;
        stderr->_write = filteringWrite;
    }
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
