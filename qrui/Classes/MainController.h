//
//  MainController.h
//  qrui
//
//  Created by Sijawusz Pur Rahnama on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DecoderController.h"


@interface MainController : UIViewController <DecoderControllerDelegate>

@property (nonatomic, retain) IBOutlet UIButton *scanButton;

- (IBAction) scan;

@end
