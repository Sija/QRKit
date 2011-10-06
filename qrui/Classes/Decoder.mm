//
//  Decoder.m
//  ZXing
//
//  Created by Christian Brunschen on 31/03/2008.
//
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

#import "Decoder.h"
#import "TwoDDecoderResult.h"

#include "QRCodeReader.h"
#include "ReaderException.h"
#include "IllegalArgumentException.h"
#include "GrayBytesMonochromeBitmapSource.h"


#ifndef TRY_ROTATIONS
    #define TRY_ROTATIONS 0
#endif
#define SUBSET_SIZE 320.0f


@implementation Decoder

@synthesize image = _image;
@synthesize cropRect = _cropRect;
@synthesize subsetImage = _subsetImage;
@synthesize subsetData = _subsetData;
@synthesize subsetWidth = _subsetWidth;
@synthesize subsetHeight = _subsetHeight;
@synthesize subsetBytesPerRow = _subsetBytesPerRow;
@synthesize delegate = _delegate;

- (void) willDecodeImage {
    [self.delegate decoder:self willDecodeImage:self.image usingSubset:self.subsetImage];
}

- (void) progressDecodingImage:(NSString *)progress {
    [self.delegate decoder:self 
             decodingImage:self.image 
               usingSubset:self.subsetImage
                  progress:progress];
}

- (void) didDecodeImage:(TwoDDecoderResult *)result {
    [self.delegate decoder:self didDecodeImage:self.image usingSubset:self.subsetImage withResult:result];
}

- (void) failedToDecodeImage:(NSString *)reason {
    [self.delegate decoder:self failedToDecodeImage:self.image usingSubset:self.subsetImage reason:reason];
}

- (void) prepareSubset {
    CGSize size = [self.image size];
    
    CGFloat scale = fminf(1.0f, fmaxf(SUBSET_SIZE / _cropRect.size.width, SUBSET_SIZE / _cropRect.size.height));
    CGPoint offset = CGPointMake(-_cropRect.origin.x, -_cropRect.origin.y);
    
    _subsetWidth = _cropRect.size.width * scale;
    _subsetHeight = _cropRect.size.height * scale;
    
    _subsetBytesPerRow = ((_subsetWidth + 0xf) >> 4) << 4;
    _subsetData = (unsigned char *) malloc(_subsetBytesPerRow * _subsetHeight);
    
    CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef ctx = 
    CGBitmapContextCreate(_subsetData, _subsetWidth, _subsetHeight, 
                          8, _subsetBytesPerRow, grayColorSpace, 
                          kCGImageAlphaNone);
    CGColorSpaceRelease(grayColorSpace);
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    CGContextSetAllowsAntialiasing(ctx, false);
    // adjust the coordinate system
    CGContextTranslateCTM(ctx, 0.0, _subsetHeight);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    UIGraphicsPushContext(ctx);
    CGRect rect = CGRectMake(offset.x * scale, offset.y * scale, scale * size.width, scale * size.height);
    [self.image drawInRect:rect];
    UIGraphicsPopContext();
    
    CGContextFlush(ctx);
    
    CGImageRef subsetImageRef = CGBitmapContextCreateImage(ctx);
    UIImage *subsetImage = [[UIImage alloc] initWithCGImage:subsetImageRef];
    
    self.subsetImage = subsetImage;
    
    [subsetImage release];
    CGImageRelease(subsetImageRef);
    
    CGContextRelease(ctx);
}

- (void) decode:(id)arg {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    {
        qrcode::QRCodeReader reader;
        Ref<MonochromeBitmapSource> grayImage(new GrayBytesMonochromeBitmapSource(_subsetData, _subsetWidth, _subsetHeight, _subsetBytesPerRow));
        TwoDDecoderResult *decoderResult = nil;
        
#if TRY_ROTATIONS
        for (int i = 0; !decoderResult && i < 4; i++) {
#endif      
            try {
                Ref<Result> result(reader.decode(grayImage));
                
                Ref<String> resultText(result->getText());
                const char *cString = resultText->getText().c_str();
                ArrayRef<Ref<ResultPoint> > resultPoints = result->getResultPoints();
                NSMutableArray *points = [NSMutableArray arrayWithCapacity:resultPoints->size()];
                
                for (size_t i = 0; i < resultPoints->size(); i++) {
                    Ref<ResultPoint> rp(resultPoints[i]);
                    CGPoint point = CGPointMake(rp->getX(), rp->getY());
                    [points addObject:[NSValue valueWithCGPoint:point]];
                }
                
                NSString *resultString = [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
                decoderResult = [TwoDDecoderResult resultWithText:resultString points:points];
                
            } catch (ReaderException rex) {
                //NSLog(@"failed to decode, caught ReaderException '%s'", rex.what());
                
            } catch (IllegalArgumentException iex) {
                //NSLog(@"failed to decode, caught IllegalArgumentException '%s'", iex.what());
                
            } catch (...) {
                //NSLog(@"Caught unknown exception!");
            }
            
#if TRY_ROTATIONS
            if (!decoderResult) {
                grayImage = grayImage->rotateCounterClockwise();
            }
        }
#endif
        
        if (decoderResult) {
            [self performSelectorOnMainThread:@selector(didDecodeImage:)
                                   withObject:decoderResult
                                waitUntilDone:NO];
        } else {
            [self performSelectorOnMainThread:@selector(failedToDecodeImage:)
                                   withObject:NSLocalizedString(@"Decoder BarcodeDetectionFailure", @"No barcode detected.")
                                waitUntilDone:NO];
        }
        
        free(_subsetData);
        self.subsetData = NULL;
    }
    [pool release];
    
    // if this is not the main thread, then we end it
    if (![NSThread isMainThread]) {
        [NSThread exit];
    }
}

- (void) decodeImage:(UIImage *)image {
    [self decodeImage:image cropRect:CGRectMake(0.0f, 0.0f, self.image.size.width, self.image.size.height)];
}

- (void) decodeImage:(UIImage *)image cropRect:(CGRect)cropRect {
    self.image = image;
    self.cropRect = cropRect;
    
    [self prepareSubset];
    [self.delegate decoder:self willDecodeImage:image usingSubset:self.subsetImage];
    
    
    [self performSelectorOnMainThread:@selector(progressDecodingImage:)
                           withObject:NSLocalizedString(@"Decoder MessageWhileDecoding", @"Decoding ...")
                        waitUntilDone:NO];  
    
    /*
    [NSThread detachNewThreadSelector:@selector(decode:) 
                             toTarget:self 
                           withObject:nil];
     */
    [self decode:nil];
}

- (void) dealloc {
    self.image = nil;
    self.subsetImage = nil;
    
    if (_subsetData) {
        free(_subsetData);
        self.subsetData = NULL;
    }
    [super dealloc];
}

@end
