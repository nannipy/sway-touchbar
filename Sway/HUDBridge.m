#import "Bridge.h"
#import <dlfcn.h>
#import <math.h>

// ABI checked against OSDManager in the installed macOS runtime.
@protocol SwayOSDAPI
+ (id)sharedManager;
- (void)showImage:(long long)image onDisplayID:(unsigned int)display priority:(unsigned int)priority msecUntilFade:(unsigned int)fade filledChiclets:(unsigned int)filled totalChiclets:(unsigned int)total locked:(BOOL)locked;
@end
static NSXPCConnection *hudConnection;
static id<SwayOSDAPI> systemHUDProxy(void) {
    if (!hudConnection) {
        NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.apple.SystemBanner" options:0];
        connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SwayOSDAPI)];
        __weak NSXPCConnection *weakConnection = connection;
        void (^reset)(void) = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSXPCConnection *failed = weakConnection;
                if (failed && failed == hudConnection) {
                    hudConnection = nil;
                    failed.interruptionHandler = nil;
                    failed.invalidationHandler = nil;
                    [failed invalidate];
                }
            });
        };
        connection.interruptionHandler = reset;
        connection.invalidationHandler = reset;
        hudConnection = connection;
        [connection resume];
    }
    NSXPCConnection *connection = hudConnection;
    __weak NSXPCConnection *weakConnection = connection;
    return [connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        // Local-only failure handling; the next user action can reconnect.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSXPCConnection *failed = weakConnection;
            if (!failed || failed != hudConnection) return;
            hudConnection = nil;
            failed.interruptionHandler = nil;
            failed.invalidationHandler = nil;
            [failed invalidate];
        });
    }];
}
BOOL SwayShowSystemHUD(int64_t graphic, uint32_t display, double value, BOOL locked) {
    if (!isfinite(value) || ![NSThread isMainThread]) return NO;
    static id<SwayOSDAPI> manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        void *framework = dlopen("/System/Library/PrivateFrameworks/OSD.framework/OSD", RTLD_LAZY | RTLD_LOCAL);
        Class cls = framework ? NSClassFromString(@"OSDManager") : Nil;
        if ([cls respondsToSelector:@selector(sharedManager)]) {
            id candidate = [(id<SwayOSDAPI>)cls sharedManager];
            if ([candidate respondsToSelector:@selector(showImage:onDisplayID:priority:msecUntilFade:filledChiclets:totalChiclets:locked:)]) manager = candidate;
        }
    });
    id<SwayOSDAPI> destination = manager;
    // Tahoe routes native Liquid Glass banners through Control Center.
    // OSDUIHelper remains installed but renders the legacy central bezel.
    // SystemBanner accepts the OSD compatibility protocol without privileged entitlements.
    if (@available(macOS 26.0, *)) destination = systemHUDProxy();
    if (!destination) return NO;
    // 100 units keeps slider feedback continuous; the system owns drawing/fade.
    [destination showImage:graphic onDisplayID:display priority:500 msecUntilFade:1000 filledChiclets:(unsigned int)lround(fmin(1, fmax(0, value)) * 100) totalChiclets:100 locked:locked];
    return YES; // Dispatch only: the private API provides no rendering acknowledgement.
}
