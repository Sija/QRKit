//
//  MainController.m
//  qrui
//
//  Created by Sijawusz Pur Rahnama on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainController.h"
#import "QRCodeReader.h"

@implementation MainController

@synthesize scanButton = _scanButton;

- (void) dealloc {
    [self viewDidUnload];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void) viewDidUnload {
    [super viewDidUnload];
    
    self.scanButton = nil;
}

#pragma mark - MainViewController

- (IBAction) scan {
    QRCodeReader *qrcodeReader = [[QRCodeReader alloc] init];
    
    DecoderController *decoderController = [[DecoderController alloc] initWithDelegate:self showCancel:YES];
    decoderController.readers = [NSSet setWithObject:qrcodeReader];
    decoderController.successSound = [Sound soundNamed:@"beep-beep.aiff"];

    [self presentModalViewController:decoderController animated:YES];
    [decoderController release];
}

#pragma mark - DecoderControllerDelegate

- (void) decoderController:(DecoderController *)controller didScanResult:(NSString *)result {
#ifdef DEBUG
    NSLog(@"decoderController:didScanResult: %@", result);
#endif
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void) decoderControllerDidCancel:(DecoderController *)controller {
    [self dismissModalViewControllerAnimated:YES];
}

@end
