//
//  ViewController.h
//  QRKitDemo
//
//  Created by Sijawusz Pur Rahnama on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QRKit/Core/QKDecoderController.h>

@interface ViewController : UIViewController <QKDecoderControllerDelegate>

- (IBAction) scan;

@end
