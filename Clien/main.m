//
//  main.m
//  Clien
//
// Copyright 2013 Changbeom Ahn
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

//int (*originalWrite)(void*, const char*, int);
//
//int filteringWrite(void* cookie, const char* buf, int nbyte)
//{
//    static char bad[] = "AssertMacros: queueEntry,  file: /SourceCache/IOKitUser/IOKitUser-920.1.11/hid.subproj/IOHIDEventQueue.c, line: 512\n";
//    static char badSim[] = "AssertMacros: queueEntry,  file: /SourceCache/IOKitUser_Sim/IOKitUser-920.1.11/hid.subproj/IOHIDEventQueue.c, line: 512\n";
//    int different = strncmp(buf, bad, nbyte) && strncmp(buf, badSim, nbyte);
//    if (different) {
//        return originalWrite(cookie, buf, nbyte);
//    }
//    return nbyte;
//}

int main(int argc, char *argv[])
{
//    if ([[UIDevice currentDevice].systemVersion isEqualToString:@"7.0"]) {
//        originalWrite = stderr->_write;
//        stderr->_write = filteringWrite;
//    }
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
