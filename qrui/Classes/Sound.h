/*
    Trivial wrapper around system sound as provided
    by Audio Services. Don’t forget to add the Audio
    Toolbox framework.
*/
#import <AudioToolbox/AudioToolbox.h>


@interface Sound : NSObject {
@private
    SystemSoundID _handle;
}

// Path is relative to the resources dir.
+ soundWithPath:(NSString *)path;
- initWithPath:(NSString *)path;

- (void) play;

@end