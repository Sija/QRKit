/**
 * Copyright 2009 Jeff Verkoeyen
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "qruiAppDelegate.h"
#import "DecoderController.h"
#import "MainController.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation qruiAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize mainController = _mainController;

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) applicationDidFinishLaunching:(UIApplication *)application {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _mainController = [[MainController alloc] initWithNibName:nil bundle:nil];
    _navigationController = [[UINavigationController alloc] initWithRootViewController:_mainController];
    _navigationController.navigationBar.tintColor = [UIColor blackColor];
    
    [_window addSubview:_navigationController.view];
    [_window makeKeyAndVisible];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) dealloc {
    self.navigationController = nil;
    self.mainController = nil;
    self.window = nil;
    [super dealloc];
}

@end
