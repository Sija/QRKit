#import "Sound.h"

@implementation Sound

+ soundNamed:(NSString *)name
{
    return [[[self alloc] initWithContentsOfFile:name] autorelease];
}

- initWithContentsOfFile:(NSString *)path
{
    if (self = [super init]) {
        NSString *const resourceDir = [[NSBundle mainBundle] resourcePath];
        NSString *const fullPath = [resourceDir stringByAppendingPathComponent:path];
        NSURL *const url = [NSURL fileURLWithPath:fullPath];
        
        OSStatus errcode = AudioServicesCreateSystemSoundID((CFURLRef)url, &_handle);
        NSAssert1(errcode == 0, @"Failed to load sound: %@", path);
    }
    return self;
}

- (void) dealloc
{
    AudioServicesDisposeSystemSoundID(_handle);
    [super dealloc];
}

- (void) play
{
    AudioServicesPlaySystemSound(_handle);
}

@end