#import "Bridge.h"
#import <dlfcn.h>
#import <math.h>

@protocol SwayKeyboardAPI
- (NSArray<NSNumber *> *)copyKeyboardBacklightIDs;
- (BOOL)isKeyboardBuiltIn:(uint64_t)keyboard;
- (float)brightnessForKeyboard:(uint64_t)keyboard;
- (BOOL)setBrightness:(float)value forKeyboard:(uint64_t)keyboard;
- (BOOL)setBrightness:(float)value fadeSpeed:(int)speed commit:(BOOL)commit forKeyboard:(uint64_t)keyboard;
- (BOOL)isIdleDimmingSuspendedOnKeyboard:(uint64_t)keyboard;
- (BOOL)suspendIdleDimming:(BOOL)suspended forKeyboard:(uint64_t)keyboard;
- (BOOL)isBacklightSaturatedOnKeyboard:(uint64_t)keyboard;
- (BOOL)isAutoBrightnessEnabledForKeyboard:(uint64_t)keyboard;
- (BOOL)enableAutoBrightness:(BOOL)enabled forKeyboard:(uint64_t)keyboard;
- (BOOL)isBacklightSuppressedOnKeyboard:(uint64_t)keyboard;
@end

static NSObject<SwayKeyboardAPI> *client(void) {
    static NSObject<SwayKeyboardAPI> *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        void *framework = dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_LAZY | RTLD_LOCAL);
        Class cls = framework ? NSClassFromString(@"KeyboardBrightnessClient") : Nil;
        NSObject *candidate = [[cls alloc] init];
        if ([candidate respondsToSelector:@selector(copyKeyboardBacklightIDs)] &&
            [candidate respondsToSelector:@selector(isKeyboardBuiltIn:)] &&
            [candidate respondsToSelector:@selector(brightnessForKeyboard:)] &&
            [candidate respondsToSelector:@selector(setBrightness:forKeyboard:)]) instance = (id)candidate;
    });
    return instance;
}
static NSNumber *keyboard(void) {
    // Prefer the built-in logical keyboard ID; fall back to enumeration.
    if ([client() isKeyboardBuiltIn:1]) return @1;
    for (NSNumber *identifier in [client() copyKeyboardBacklightIDs]) {
        if ([client() isKeyboardBuiltIn:identifier.unsignedLongLongValue]) return identifier;
    }
    return nil;
}
float SwayKeyboardBrightness(void) {
    NSNumber *identifier = keyboard();
    return identifier ? [client() brightnessForKeyboard:identifier.unsignedLongLongValue] : NAN;
}
BOOL SwaySetKeyboardBrightness(float value) {
    NSNumber *identifier = keyboard();
    if (!identifier || !isfinite(value)) return NO;
    value = fminf(1, fmaxf(0, value));
    if ([client() respondsToSelector:@selector(setBrightness:fadeSpeed:commit:forKeyboard:)]) {
        return [client() setBrightness:value fadeSpeed:0 commit:YES forKeyboard:identifier.unsignedLongLongValue];
    }
    return [client() setBrightness:value forKeyboard:identifier.unsignedLongLongValue];
}
BOOL SwayKeyboardSuppressed(void) {
    NSNumber *identifier = keyboard();
    return identifier && [client() respondsToSelector:@selector(isBacklightSuppressedOnKeyboard:)] && [client() isBacklightSuppressedOnKeyboard:identifier.unsignedLongLongValue];
}

BOOL SwayKeyboardSaturated(void) {
    NSNumber *identifier = keyboard();
    return identifier && [client() respondsToSelector:@selector(isBacklightSaturatedOnKeyboard:)] && [client() isBacklightSaturatedOnKeyboard:identifier.unsignedLongLongValue];
}
BOOL SwayKeyboardAutomatic(void) {
    NSNumber *identifier = keyboard();
    return identifier && [client() respondsToSelector:@selector(isAutoBrightnessEnabledForKeyboard:)] && [client() isAutoBrightnessEnabledForKeyboard:identifier.unsignedLongLongValue];
}
BOOL SwaySetKeyboardAutomatic(BOOL enabled) {
    NSNumber *identifier = keyboard();
    return identifier && [client() respondsToSelector:@selector(enableAutoBrightness:forKeyboard:)] && [client() enableAutoBrightness:enabled forKeyboard:identifier.unsignedLongLongValue];
}

BOOL SwayKeyboardIdleSuspended(void) {
    NSNumber *identifier = keyboard();
    return identifier && [client() respondsToSelector:@selector(isIdleDimmingSuspendedOnKeyboard:)] && [client() isIdleDimmingSuspendedOnKeyboard:identifier.unsignedLongLongValue];
}
BOOL SwaySetKeyboardIdleSuspended(BOOL suspended) {
    NSNumber *identifier = keyboard();
    return identifier && [client() respondsToSelector:@selector(isIdleDimmingSuspendedOnKeyboard:)] && [client() respondsToSelector:@selector(suspendIdleDimming:forKeyboard:)] && [client() suspendIdleDimming:suspended forKeyboard:identifier.unsignedLongLongValue];
}
