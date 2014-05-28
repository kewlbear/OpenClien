//
//  OCBoard.m
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

#import "OCBoard.h"

static NSString *kURL = @"url";
static NSString *kTitle = @"title";

@implementation OCBoard

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _URL = [aDecoder decodeObjectForKey:kURL];
        _title = [aDecoder decodeObjectForKey:kTitle];
    }
    return self;
}

- (BOOL)isImage
{
    return [_URL.query rangeOfString:@"bo_table=image"].length;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_URL forKey:kURL];
    [aCoder encodeObject:_title forKey:kTitle];
}


@end
