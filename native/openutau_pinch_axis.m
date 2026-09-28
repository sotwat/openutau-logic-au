#import <AppKit/AppKit.h>
#include <math.h>

static id monitor;
static int axis;
static id firstIdentity;
static id secondIdentity;
static double previousX;
static double previousY;
static BOOL hasPrevious;

// 0: unknown, 1: horizontal, 2: vertical.
int ou_pinch_axis(void) { return axis; }

int ou_pinch_classify(double changeX, double changeY) {
    double x = fabs(changeX);
    double y = fabs(changeY);
    if (x < 0.5 && y < 0.5) return 0;
    if (x > y * 1.25) return 1;
    if (y > x * 1.25) return 2;
    return 0;
}

static void observe(NSEvent *event) {
    event.window.contentView.allowedTouchTypes |= NSTouchTypeMaskIndirect;
    if (event.phase == NSEventPhaseBegan) {
        axis = 0;
        hasPrevious = NO;
    }
    NSArray<NSTouch *> *touches = [[event allTouches] allObjects];
    if (touches.count != 2) {
        if (event.phase == NSEventPhaseEnded || event.phase == NSEventPhaseCancelled) {
            axis = 0;
            hasPrevious = NO;
        }
        return;
    }
    NSTouch *a = touches[0];
    NSTouch *b = touches[1];
    NSSize size = a.deviceSize;
    double x = fabs(a.normalizedPosition.x - b.normalizedPosition.x) * size.width;
    double y = fabs(a.normalizedPosition.y - b.normalizedPosition.y) * size.height;
    if (hasPrevious &&
        (([firstIdentity isEqual:a.identity] && [secondIdentity isEqual:b.identity]) ||
         ([firstIdentity isEqual:b.identity] && [secondIdentity isEqual:a.identity]))) {
        int candidate = ou_pinch_classify(x - previousX, y - previousY);
        if (candidate) axis = candidate;
    } else {
        axis = 0;
    }
    firstIdentity = a.identity;
    secondIdentity = b.identity;
    previousX = x;
    previousY = y;
    hasPrevious = YES;
}

int ou_pinch_start(void) {
    if (monitor) return 1;
    for (NSWindow *window in NSApp.windows) {
        window.contentView.allowedTouchTypes |= NSTouchTypeMaskIndirect;
    }
    monitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskMagnify
                                               handler:^NSEvent *(NSEvent *event) {
        observe(event);
        return event;
    }];
    return monitor != nil;
}
