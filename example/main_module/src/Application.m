#import "SomeLib.h"
#import "SomeLib+Eating.h"
#import "Application.h"

@implementation Application

- (void)applicationDidFinishLaunching:(OFNotification *)notification {
  @autoreleasepool {
    SomeLib *sl = [[SomeLib alloc] init];

    [sl printHello];
    [sl eat];
  }

  [OFApplication terminate];
}

@end
