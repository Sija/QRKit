//
//  QKDecoder.m
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

#import "QKDecoder.h"
#import "QK2DDecoderResult.h"
#import "QKFormatReader.h"

#include <zxing/BinaryBitmap.h>
#include <zxing/ReaderException.h>
#include <zxing/common/IllegalArgumentException.h>
#include <zxing/common/HybridBinarizer.h>
#include <zxing/common/GreyscaleLuminanceSource.h>

using namespace zxing;


class ZXingDecoderCallback : public ResultPointCallback {
private:
    QKDecoder *_decoder;
public:
    ZXingDecoderCallback(QKDecoder *decoder) : _decoder(decoder) {}
    void foundPossibleResultPoint(ResultPoint const& result) {
        CGPoint point;
        point.x = result.getX();
        point.y = result.getY();
        [_decoder resultPointCallback:point];
    }
};


#ifndef TRY_ROTATIONS
    #define TRY_ROTATIONS 0
#endif
#define SUBSET_SIZE 320.0f


@implementation QKDecoder

@synthesize image = _image;
@synthesize readers = _readers;
@synthesize cropRect = _cropRect;
@synthesize subsetImage = _subsetImage;
@synthesize subsetData = _subsetData;
@synthesize subsetWidth = _subsetWidth;
@synthesize subsetHeight = _subsetHeight;
@synthesize subsetBytesPerRow = _subsetBytesPerRow;
@synthesize delegate = _delegate;

- initWithDelegate:(id<QKDecoderDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void) willDecodeImage {
    [self.delegate decoder:self willDecodeImage:self.image usingSubset:self.subsetImage];
}

- (void) didDecodeImage:(QK2DDecoderResult *)result {
    [self.delegate decoder:self didDecodeImage:self.image usingSubset:self.subsetImage withResult:result];
}

- (void) failedToDecodeImage:(NSString *)reason {
    [self.delegate decoder:self failedToDecodeImage:self.image usingSubset:self.subsetImage reason:reason];
}

- (void) resultPointCallback:(CGPoint)point {
    if ([self.delegate respondsToSelector:@selector(decoder:foundPossibleResultPoint:)]) {
        [self.delegate decoder:self foundPossibleResultPoint:point];
    }
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

- (void) decode {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    {
        QK2DDecoderResult *decoderResult = nil;
        
        Ref<LuminanceSource> source(new GreyscaleLuminanceSource(_subsetData, _subsetBytesPerRow, _subsetHeight, 0, 0, _subsetWidth, _subsetHeight));
        Ref<Binarizer> binarizer(new HybridBinarizer(source));
        source = NULL;
        Ref<BinaryBitmap> grayImage(new BinaryBitmap(binarizer));
        binarizer = NULL;
        
#ifdef DEBUG
        NSLog(@"Created GreyscaleLuminanceSource(%p, %d, %d, %d, %d, %d, %d)",
              _subsetData, _subsetBytesPerRow, _subsetHeight, 0, 0, _subsetWidth, _subsetHeight);
        NSLog(@"grayImage count = %d", grayImage->count());
#endif
        
#if TRY_ROTATIONS
        for (int i = 0; !decoderResult && i < 4; i++) {
#endif
            for (QKFormatReader *reader in self.readers) {
                try {
#ifdef DEBUG
                    NSLog(@"Decoding gray image");
#endif  
                    ResultPointCallback* callback_pointer(new ZXingDecoderCallback(self));
                    Ref<ResultPointCallback> callback(callback_pointer);
                    Ref<Result> result([reader decode:grayImage andCallback:callback]);
#ifdef DEBUG
                    NSLog(@"Gray image decoded");
#endif
                    
                    Ref<String> resultText(result->getText());
                    const char *cString = resultText->getText().c_str();
                    const std::vector<Ref<ResultPoint> > &resultPoints = result->getResultPoints();
                    NSMutableArray *points = [NSMutableArray arrayWithCapacity:resultPoints.size()];
                    
                    for (size_t i = 0; i < resultPoints.size(); i++) {
                        const Ref<ResultPoint> &rp = resultPoints[i];
                        CGPoint point = CGPointMake(rp->getX(), rp->getY());
                        [points addObject:[NSValue valueWithCGPoint:point]];
                    }
                    
                    NSString *resultString = [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
                    decoderResult = [QK2DDecoderResult resultWithText:resultString points:points];
                    
                } catch (ReaderException &rex) {
#ifdef DEBUG
                    NSLog(@"Failed to decode, caught ReaderException '%s'", rex.what());
#endif
                } catch (IllegalArgumentException &iex) {
#ifdef DEBUG
                    NSLog(@"Failed to decode, caught IllegalArgumentException '%s'", iex.what());
#endif
                } catch (...) {
                    NSLog(@"Caught unknown exception!");
                }
            }
            
#if TRY_ROTATIONS
            if (!decoderResult) {
#ifdef DEBUG
                NSLog(@"Rotating gray image");
#endif
                grayImage = grayImage->rotateCounterClockwise();
#ifdef DEBUG
                NSLog(@"Gray image rotated");
#endif
            }
        }
#endif
        
        free(_subsetData);
        self.subsetData = NULL;        
        
        if (decoderResult) {
            [self performSelectorOnMainThread:@selector(didDecodeImage:)
                                   withObject:[decoderResult copy]
                                waitUntilDone:NO];
        } else {
            [self performSelectorOnMainThread:@selector(failedToDecodeImage:)
                                   withObject:NSLocalizedString(@"QKDecoder BarcodeDetectionFailure", @"No barcode detected.")
                                waitUntilDone:NO];
        }
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
    [self performSelectorOnMainThread:@selector(willDecodeImage) withObject:nil waitUntilDone:NO];
    
    /*
    [NSThread detachNewThreadSelector:@selector(decode) 
                             toTarget:self 
                           withObject:nil];
     */
    [self performSelectorOnMainThread:@selector(decode) withObject:nil waitUntilDone:NO];
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
