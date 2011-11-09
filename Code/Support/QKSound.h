//
//  QKSound.h
//
//  Created by zoul on 7/25/11.
//  Copyright 2011 zoul. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

/**
 * Trivial wrapper around system sound as provided
 * by Audio Services. Don’t forget to add the Audio
 * Toolbox framework.
 */
@interface QKSound : NSObject {
@private
    SystemSoundID _handle;
}

// Path is relative to the resources dir.
+ soundNamed:(NSString *)name;
- initWithContentsOfFile:(NSString *)path;

- (void) play;

@end