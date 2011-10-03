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

#import <AVFoundation/AVFoundation.h>
#import "DecoderDelegate.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

@class OverlayView;
@class Decoder;
@class DecoderController;


////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol DecoderControllerDelegate <NSObject>

@optional
- (void) decoderController:(DecoderController *)controller didScanResult:(NSString *)result;
- (void) decoderControllerDidCancel:(DecoderController *)controller;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface DecoderController : UIViewController <
    UIAlertViewDelegate,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    DecoderDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate
>

@property (nonatomic, assign) id<DecoderControllerDelegate> delegate;
@property (nonatomic, retain) OverlayView* overlayView;
@property (nonatomic, retain) Decoder* decoder;
@property (nonatomic, assign, getter = isDecoding) BOOL decoding;

- (id) initWithDelegate:(id<DecoderControllerDelegate>)delegate showCancel:(BOOL)shouldShowCancel;

@end
