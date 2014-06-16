//
//  GDataXMLNode+OpenClien.h
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

#import "GDataXMLNode.h"

/**
 파서 구현을 위한 편의 카테고리이다.
 */
@interface GDataXMLNode (OpenClien)

/**
 주어진 XPath 질의를 수신자에 적용한 결과를 반환한다.
 
 @param key 수신자에 적용할 XPath 질의
 
 @return 주어진 XPath 질의를 수신자에 적용한 결과
 */
- (NSArray *)objectForKeyedSubscript:(id)key;

@end
