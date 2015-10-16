//
//  OCSession.m
//  Example
//
// Copyright 2014 Changbeom Ahn
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

#import "OCSession.h"
#import <OpenClien/OpenClien.h>
#import "AFNetworking.h"

static NSString *kId = @"id";
static NSString *kPassword = @"password";

@implementation OCSession
{
    OCSessionBlock _block;
    NSURL *_URL;
}

+ (OCSession *)defaultSession
{
    static OCSession *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OCSession alloc] init];
    });
    return instance;
}

- (void)loginWithId:(NSString *)loginId password:(NSString *)password URL:(NSURL *)url completion:(OCSessionBlock)block
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSString *logoutURL = [OCLoginParser URL].absoluteString;
    NSDictionary *parameters = [OCLoginParser parametersForId:loginId password:password URL:url];
    [manager POST:logoutURL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"로그인: %@", [[NSString alloc] initWithBytes:[responseObject bytes] length:[responseObject length] encoding:NSUTF8StringEncoding]);
        if (block) {
            OCLoginParser *parser = [[OCLoginParser alloc] init];
            NSError *error;
            if ([parser parse:responseObject error:&error]) {
                [[NSUserDefaults standardUserDefaults] setObject:loginId forKey:kId];
                [[NSUserDefaults standardUserDefaults] setObject:password forKey:kPassword];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(error);
                });
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"로그인: %@", error);
        if (block) {
            block(error);
        }
    }];
    NSLog(@"로그인 요청");
}

- (void)logout:(OCSessionBlock)block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[OCLogoutParser URL]];
        OCLogoutParser *parser = [[OCLogoutParser alloc] init];
        // fixme
        [parser parse:data];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kId];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPassword];
        
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil);
            });
        }
    });
}

- (void)autoLogin:(OCSessionBlock)block
{
    NSString *login = [[NSUserDefaults standardUserDefaults] objectForKey:kId];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:kPassword];
    if (login && password) {
        NSURL *url = [NSURL URLWithString:@"http://clien.net"];
        [self loginWithId:login password:password URL:url completion:block];
    } else {
        // NOTE: 로그인 페이지로 보내지 않도록
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://clien.net"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"%@", data);
        }] resume];
        
        if (block) {
            block([NSError errorWithDomain:@"OpenClienExampleErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"저장된 로그인 정보가 없습니다."}]);
        }
    }
}

- (void)showLoginAlertView:(OCSessionBlock)block URL:(NSURL *)URL
{
    _block = block;
    _URL = URL;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"로그인", nil];
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSString *login = [alertView textFieldAtIndex:0].text;
        NSString *password = [alertView textFieldAtIndex:1].text;
        //        NSLog(@"l=%@ p=%@", login, password);
        [self loginWithId:login password:password URL:_URL completion:^(NSError *error) {
            _block(error);
        }];
    }
}

@end
