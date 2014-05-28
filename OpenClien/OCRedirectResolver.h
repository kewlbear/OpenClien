//
//  OCRedirectResolver.h
//  OpenClien
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

#import <Foundation/Foundation.h>

typedef void(^OCRedirectResolverBlock)(NSURL *url);

/**
 최종 URL이 클리앙인지 확인
 */
@interface OCRedirectResolver : NSObject

/**
 URL 리디렉션을 추적하여 최종 URL을 block에 전달한다.
 */
- (void)resolve:(NSURL *)url completion:(OCRedirectResolverBlock)block;

@end
