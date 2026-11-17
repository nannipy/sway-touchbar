#import <AppKit/AppKit.h>
@interface NSTouchBar (SwayPrivate)
+ (void)presentSystemModalTouchBar:(NSTouchBar * _Nonnull)bar placement:(long long)placement systemTrayItemIdentifier:(NSString * _Nullable)identifier;
+ (void)dismissSystemModalTouchBar:(NSTouchBar * _Nonnull)bar;
@end
// Isolated CoreBrightness adapter; unavailable hardware returns NAN/false.
float SwayKeyboardBrightness(void);
BOOL SwaySetKeyboardBrightness(float value);
BOOL SwayKeyboardSuppressed(void);
BOOL SwayKeyboardSaturated(void);
BOOL SwayKeyboardAutomatic(void);
BOOL SwaySetKeyboardAutomatic(BOOL enabled);
BOOL SwayKeyboardIdleSuspended(void);
BOOL SwaySetKeyboardIdleSuspended(BOOL suspended);
BOOL SwayShowSystemHUD(int64_t graphic, uint32_t display, double value, BOOL locked);
