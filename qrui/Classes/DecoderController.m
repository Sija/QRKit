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

#import "DecoderController.h"
#import "UIImage-Extensions.h"

#import "OverlayView.h"

#import "Decoder.h"
#import "TwoDDecoderResult.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface DecoderController ()

@property (nonatomic, retain) AVCaptureSession*           captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer* previewLayer;

- (void) startCapture;
- (void) stopCapture;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation DecoderController

@synthesize delegate = _delegate;
@synthesize overlayView = _overlayView;
@synthesize decoder = _decoder;
@synthesize decoding = _decoding;
@synthesize captureSession = _captureSession;
@synthesize previewLayer = _previewLayer;
@synthesize wasStatusBarHidden = _wasStatusBarHidden;


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id) initWithDelegate:(id<DecoderControllerDelegate>)delegate showCancel:(BOOL)shouldShowCancel {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.wantsFullScreenLayout = YES;
    }
    return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) dealloc {
    [self viewDidUnload];
    
    [super dealloc];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) loadView {
    [super loadView];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) viewDidUnload {
    [super viewDidUnload];
    [self stopCapture];
    
    self.delegate = nil;
    self.overlayView = nil;
    self.decoder = nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _wasStatusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    if (!_wasStatusBarHidden) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Not a supported device"
                                  message:@"You need a camera to run this app"
                                  delegate:self
                                  cancelButtonTitle:@"Darn"
                                  otherButtonTitles:nil];
        
        [alertView show];
        
    } else {
        if (nil != _overlayView) {
            return;
        }
        //[self performSelector:@selector(startCapture) withObject:nil afterDelay:0.0];
        [self startCapture];
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (!_wasStatusBarHidden) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    _decoding = NO;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_overlayView removeFromSuperview];
    [self stopCapture];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIAlertViewDelegate


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView release];
    
    UIViewController *parent = self.parentViewController;
    if (parent && parent.modalViewController == self) {
        [parent dismissModalViewControllerAnimated:YES];
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark AVFoundation related


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) startCapture {
    _decoding = YES;
    
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:nil];
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init]; 
    [captureOutput setAlwaysDiscardsLateVideoFrames:YES];
    [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    NSString *key = (NSString *) kCVPixelBufferPixelFormatTypeKey; 
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = AVCaptureSessionPresetMedium; // 480x360 on a 4
    
    [_captureSession addInput:captureInput];
    [_captureSession addOutput:captureOutput];

    [captureOutput release];
    
    /*
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(stopPreview:)
     name:AVCaptureSessionDidStopRunningNotification
     object:_captureSession];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(notification:)
     name:AVCaptureSessionDidStopRunningNotification
     object:_captureSession];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(notification:)
     name:AVCaptureSessionRuntimeErrorNotification
     object:_captureSession];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(notification:)
     name:AVCaptureSessionDidStartRunningNotification
     object:_captureSession];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(notification:)
     name:AVCaptureSessionWasInterruptedNotification
     object:_captureSession];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(notification:)
     name:AVCaptureSessionInterruptionEndedNotification
     object:_captureSession];
    */
    
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    }
    // NSLog(@"prev %p %@", _previewLayer, _previewLayer);
    _previewLayer.frame = self.view.bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:_previewLayer];
    
    if (!_overlayView) {
        _overlayView = [[OverlayView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [self.view addSubview:_overlayView];
    }
    [_captureSession performSelector:@selector(startRunning) withObject:nil afterDelay:0.0];
    //[_captureSession startRunning];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) stopCapture {
    _decoding = NO;
    
    if (nil != _captureSession) {
        [_captureSession stopRunning];
        AVCaptureInput *input = [_captureSession.inputs objectAtIndex:0];
        [_captureSession removeInput:input];
        AVCaptureVideoDataOutput *output = (AVCaptureVideoDataOutput *) [_captureSession.outputs objectAtIndex:0];
        [_captureSession removeOutput:output];
    }
    if (nil != _previewLayer) {
        [_previewLayer removeFromSuperlayer];
    }
    self.previewLayer = nil;
    self.captureSession = nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!_decoding) {
        //NSLog(@"Capturing while stopped!");
        return;
    }
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    // Lock the image buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0); 
    // Get information about the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer); 
    
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 
    void *free_me = NULL;
    if (true) { // iPhone 3G bug
        uint8_t *tmp = baseAddress;
        int bytes = bytesPerRow * height;
        free_me = baseAddress = (uint8_t *) malloc(bytes);
        baseAddress[0] = 0xdb;
        memcpy(baseAddress, tmp, bytes);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst); 
    
    CGImageRef capture = CGBitmapContextCreateImage(newContext);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    free(free_me);
    
    CGContextRelease(newContext); 
    CGColorSpaceRelease(colorSpace);
    
    CGRect cropRect = [_overlayView cropRect];
     // N.B.
     // - Won't work if the overlay becomes uncentered ...
     // - iOS always takes videos in landscape
     // - images are always 4x3; device is not
     // - iOS uses virtual pixels for non-image stuff
    {
        size_t height = CGImageGetHeight(capture);
        size_t width = CGImageGetWidth(capture);
                
        cropRect.origin.x = (width - cropRect.size.width) / 2;
        cropRect.origin.y = (height - cropRect.size.height) / 2;
    }

    CGImageRef newImage = CGImageCreateWithImageInRect(capture, cropRect);
    CGImageRelease(capture);
    UIImage *image = [[UIImage alloc] initWithCGImage:newImage];
    CGImageRelease(newImage);
    
    UIImage *rotated = [image imageRotatedByDegrees:90.f];

    if (nil == _decoder) {
        _decoder = [[Decoder alloc] init];
        _decoder.delegate = self;
    }

    //Decoder *decoder = [[Decoder alloc] init];
    //decoder.delegate = self;

    cropRect.origin = CGPointZero;
    [_decoder decodeImage:rotated cropRect:cropRect];
    
    [image release];
    //[decoder release];
} 


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark DecoderDelegate


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) decoder:(Decoder *)decoder willDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset {
    //NSLog(@"willDecodeImage");
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) decoder:(Decoder *)decoder decodingImage:(UIImage *)image usingSubset:(UIImage *)subset progress:(NSString *)message {
    //NSLog(@"decodingImage");
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) decoder:(Decoder *)decoder didDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset withResult:(TwoDDecoderResult *)result {
    NSLog(@"didDecodeImage");
    NSLog(@"%@", result.text);
    NSLog(@"%@", result.points);
    
    _overlayView.image = image;
    _overlayView.points = result.points;
    
    //[self stopCapture];
    _decoding = NO;
    
    if ([self.delegate respondsToSelector:@selector(decoderController:didScanResult:)]) {
        [self.delegate decoderController:self didScanResult:result.text];
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) decoder:(Decoder *)decoder failedToDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset reason:(NSString *)reason {
    //NSLog(@"failedToDecodeImage");
    
    _overlayView.image = nil;
    _overlayView.points = nil;
}


@end

