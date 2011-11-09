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

#import "UIImage-Extensions.h"
#import "QKDecoderController.h"
#import "QKOverlayView.h"
#import "QKDecoder.h"
#import "QK2DDecoderResult.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface QKDecoderController ()

@property (nonatomic, retain) AVCaptureSession*           captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer* previewLayer;

@property (nonatomic, assign) BOOL                        wasStatusBarHidden;
@property (nonatomic, assign, getter = isDecoding) BOOL   decoding;

- (void) startCapture;
- (void) stopCapture;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation QKDecoderController

@synthesize readers = _readers;
@synthesize delegate = _delegate;
@synthesize overlayView = _overlayView;
@synthesize decoder = _decoder;
@synthesize successSound = _successSound;
@synthesize decoding = _decoding;
@synthesize captureSession = _captureSession;
@synthesize previewLayer = _previewLayer;
@synthesize wasStatusBarHidden = _wasStatusBarHidden;


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id) initWithDelegate:(id<QKDecoderControllerDelegate>)delegate showCancel:(BOOL)shouldShowCancel {
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
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) dealloc {
    [self viewDidUnload];
    [super dealloc];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark View lifecycle


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) viewDidLoad {
    [super viewDidLoad];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) viewDidUnload {
    [super viewDidUnload];
    [self stopCapture];
    
    self.delegate = nil;
    self.overlayView = nil;
    self.decoder = nil;
    self.successSound = nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
        if (self.isDecoding || _overlayView) {
            return;
        }
        // TODO: why do i need this?
        self.view.frame = [UIScreen mainScreen].bounds;
        
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
    self.decoding = NO;
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
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    if (self.isDecoding || !captureInput) {
        return;
    }
    self.decoding = YES;
    
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
    
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    }
    // NSLog(@"prev %p %@", _previewLayer, _previewLayer);
    
    _previewLayer.frame = self.view.bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:_previewLayer];
    
    if (!_overlayView) {
        _overlayView = [[QKOverlayView alloc] initWithFrame:_previewLayer.frame];
        [self.view addSubview:_overlayView];
    }
    [_captureSession performSelector:@selector(startRunning) withObject:nil afterDelay:0.0];
    //[_captureSession startRunning];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) stopCapture {
    self.decoding = NO;
    
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
    if (!self.isDecoding) {
        return;
    }
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    // Lock the image buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0); 
    // Get information about the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer); 
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 
    void *free_me = NULL;
    if (true) { // iPhone 3G bug
        void *tmp = baseAddress;
        int bytes = bytesPerRow * height;
        free_me = baseAddress = malloc(bytes);
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

    // NOT thread safe
    if (nil == _decoder) {
        _decoder = [[QKDecoder alloc] initWithDelegate:self];
        _decoder.readers = _readers;
    }

    cropRect.origin = CGPointZero;
    [_decoder decodeImage:rotated cropRect:cropRect];
    [image release];
} 


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark QKDecoderDelegate


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) decoder:(QKDecoder *)decoder willDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset {
#ifdef DEBUG
    NSLog(@"decoder:willDecodeImage");
#endif
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) decoder:(QKDecoder *)decoder didDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset withResult:(QK2DDecoderResult *)result {
#ifdef DEBUG
    NSLog(@"decoder:didDecodeImage");
    NSLog(@"%@", result.text);
    NSLog(@"%@", result.points);
#endif
    
    _overlayView.image = image;
    _overlayView.points = result.points;
    
    //[self stopCapture];
    self.decoding = NO;
    
    if ([self.delegate respondsToSelector:@selector(decoderController:didScanResult:)]) {
        [self.delegate decoderController:self didScanResult:result.text];
    }
    if (self.successSound) {
        [self.successSound play];
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) decoder:(QKDecoder *)decoder failedToDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset reason:(NSString *)reason {
#ifdef DEBUG
    NSLog(@"decoder:failedToDecodeImage:%@", reason);
#endif
    
    _overlayView.image = nil;
    _overlayView.points = nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) decoder:(QKDecoder *)decoder foundPossibleResultPoint:(CGPoint)point {
#ifdef DEBUG
    NSLog(@"decoder:foundPossibleResultPoint:%@", NSStringFromCGPoint(point));
#endif
}

@end

