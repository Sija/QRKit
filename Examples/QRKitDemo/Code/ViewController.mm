//
//  ViewController.m
//  QRKitDemo
//
//  Created by Sijawusz Pur Rahnama on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <QRKit/Core/QKQRCodeReader.h>
#import "ViewController.h"

@implementation ViewController

- (IBAction) scan
{
    QKQRCodeReader *qrcodeReader = [[QKQRCodeReader alloc] init];
    
    QKDecoderController *decoderController = [[QKDecoderController alloc] initWithDelegate:self showCancel:YES];
    decoderController.readers = [NSSet setWithObject:qrcodeReader];
    decoderController.successSound = [QKSound soundNamed:@"beep-beep.aiff"];
    
    [self presentModalViewController:decoderController animated:YES];
    [qrcodeReader release];
    [decoderController release];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark - 
#pragma mark QKDecoderControllerDelegate

- (void) decoderController:(QKDecoderController *)controller didScanResult:(NSString *)result
{
    NSLog(@"decoderController:didScanResult: %@", result);
    [self dismissModalViewControllerAnimated:YES];
}

- (void) decoderControllerDidCancel:(QKDecoderController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
