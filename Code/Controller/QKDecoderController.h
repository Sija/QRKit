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
#import "QKDecoderDelegate.h"
#import "QKSound.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

@class QKOverlayView;
@class QKDecoder;
@class QKDecoderController;


////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol QKDecoderControllerDelegate <NSObject>
@optional
- (void) decoderController:(QKDecoderController *)controller didScanResult:(NSString *)result;
- (void) decoderControllerDidCancel:(QKDecoderController *)controller;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface QKDecoderController : UIViewController <
    UIAlertViewDelegate,
    UINavigationControllerDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    QKDecoderDelegate
>

@property (nonatomic, retain) NSSet *readers;
@property (nonatomic, assign) id<QKDecoderControllerDelegate> delegate;
@property (nonatomic, retain) QKOverlayView* overlayView;
@property (nonatomic, retain) QKDecoder* decoder;
@property (nonatomic, retain) QKSound *successSound;

- (id) initWithDelegate:(id<QKDecoderControllerDelegate>)delegate showCancel:(BOOL)shouldShowCancel;

@end
