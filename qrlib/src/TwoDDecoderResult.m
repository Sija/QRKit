//
//  TwoDDecoderResult.m
//  ZXing
//
//  Created by Christian Brunschen on 04/06/2008.
/*
 * Copyright 2008 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "TwoDDecoderResult.h"


@implementation TwoDDecoderResult

@synthesize text = _text;
@synthesize points = _points;

+ resultWithText:(NSString *)text points:(NSArray *)points {
    return [[[self alloc] initWithText:text points:points] autorelease];
}

- initWithText:(NSString *)text points:(NSArray *)points {
    self = [super init];
    if (self) {
        self.text = text;
        self.points = points;
    }
    return self;
}

- copyWithZone:(NSZone *)zone {
    NSArray* newPoints = [[[NSArray alloc] initWithArray:_points] autorelease];
    NSString* newText = [[[NSString alloc] initWithString:_text] autorelease];
    
    return [[[self class] allocWithZone:zone] initWithText:newText points:newPoints];
}

- copy {
    return [self copyWithZone:nil];
}

- (void) dealloc {
    self.text = nil;
    self.points = nil;
    [super dealloc];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"<%@: %p> %@", [self class], self, self.text];
}

@end
