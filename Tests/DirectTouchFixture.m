#import "DirectTouchFixture.h"

@interface SwayTestTouch : NSTouch
@property(nonatomic) NSTouchPhase testPhase;
@property(nonatomic) CGFloat x;
@end
@implementation SwayTestTouch
- (id<NSObject, NSCopying>)identity { return @"sway-test-finger"; }
- (NSTouchPhase)phase { return self.testPhase; }
- (NSTouchType)type { return NSTouchTypeDirect; }
- (NSPoint)locationInView:(NSView *)view { return NSMakePoint(self.x, 14); }
@end
@interface SwayTestEvent : NSEvent
@property(nonatomic, strong) SwayTestTouch *testTouch;
@property(nonatomic, weak) NSView *testView;
@end
@implementation SwayTestEvent
- (NSEventType)type { return NSEventTypeDirectTouch; }
- (NSSet<NSTouch *> *)touchesMatchingPhase:(NSTouchPhase)phase inView:(NSView *)view {
    if ((self.testTouch.phase & phase) && (!view || view == self.testView)) return [NSSet setWithObject:self.testTouch];
    return [NSSet set];
}
// Apple declares allTouches valid only for NSEventTypeGesture, not DirectTouch.
- (NSSet<NSTouch *> *)allTouches { return [NSSet set]; }
@end
NSEvent *SwayTestDirectEvent(NSTouchPhase phase, CGFloat x, NSView *view) {
    SwayTestTouch *touch = [SwayTestTouch new]; touch.testPhase = phase; touch.x = x;
    SwayTestEvent *event = [SwayTestEvent new]; event.testTouch = touch; event.testView = view;
    return event;
}
