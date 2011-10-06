//
//  MainController.m
//  qrui
//
//  Created by Sijawusz Pur Rahnama on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainController.h"


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

- (IBAction) scan:(id)sender {
    DecoderController *decoderController = [[DecoderController alloc] initWithDelegate:self showCancel:YES];
    /*
    decoderController.soundToPlay = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"beep-beep"
                                                                                           ofType:@"aiff"] isDirectory:NO];
     */
    [self presentModalViewController:decoderController animated:YES];
    [decoderController release];
}

#pragma mark - DecoderControllerDelegate

- (void) decoderController:(DecoderController *)controller didScanResult:(NSString *)result {
    NSLog(@"decoderController:didScanResult: %@", result);
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void) decoderControllerDidCancel:(DecoderController *)controller {
    [self dismissModalViewControllerAnimated:YES];
}

@end
