#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <math.h>
#ifdef OPENUTAU_PINCH_DEBUG
#include <stdio.h>
#endif

static id monitor;
static id windowObserver;
static int axis;
static id firstIdentity;
static id secondIdentity;
static double initialX;
static double initialY;
static BOOL hasInitial;

// 0: unknown, 1: horizontal, 2: vertical.
int ou_pinch_axis(void) { return axis; }

int ou_pinch_classify(double changeX, double changeY) {
    double x = fabs(changeX), y = fabs(changeY);
    if (x < 0.5 && y < 0.5) return 0;
    if (x > y * 1.25) return 1;
    if (y > x * 1.25) return 2;
    return 0;
}

static void observeTouches(NSView *view, NSEvent *event) {
    NSArray<NSTouch *> *touches = [[event touchesMatchingPhase:NSTouchPhaseTouching inView:view] allObjects];
    if (touches.count != 2) {
        hasInitial = NO;
        axis = 0;
    } else {
        NSTouch *a = touches[0], *b = touches[1];
        NSSize size = a.deviceSize;
        double x = fabs(a.normalizedPosition.x - b.normalizedPosition.x) * size.width;
        double y = fabs(a.normalizedPosition.y - b.normalizedPosition.y) * size.height;
        BOOL samePair = hasInitial &&
            (([firstIdentity isEqual:a.identity] && [secondIdentity isEqual:b.identity]) ||
             ([firstIdentity isEqual:b.identity] && [secondIdentity isEqual:a.identity]));
        if (!samePair) {
            initialX = x;
            initialY = y;
            firstIdentity = a.identity;
            secondIdentity = b.identity;
            hasInitial = YES;
            axis = ou_pinch_classify(x, y);
        } else {
            int candidate = ou_pinch_classify(x - initialX, y - initialY);
            if (candidate) axis = candidate;
        }
    }
#ifdef OPENUTAU_PINCH_DEBUG
    FILE *log = fopen("/tmp/openutau-pinch-axis-debug.log", "a");
    if (log) {
        fprintf(log, "raw touches=%lu axis=%d view=%s\n", (unsigned long)touches.count,
                axis, class_getName(object_getClass(view)));
        fclose(log);
    }
#endif
}

static void touchEvent(id self, SEL selector, NSEvent *event) {
    observeTouches(self, event);
    struct objc_super parent = {self, class_getSuperclass(object_getClass(self))};
    ((void (*)(struct objc_super *, SEL, NSEvent *))objc_msgSendSuper)(&parent, selector, event);
}

static void attach(NSView *view) {
    if (!view) return;
    Class original = object_getClass(view);
    const char *name = class_getName(original);
    if (strncmp(name, "OUTrackpad_", 11) != 0) {
        NSString *subclassName = [@"OUTrackpad_" stringByAppendingString:NSStringFromClass(original)];
        Class subclass = NSClassFromString(subclassName);
        if (!subclass) {
            subclass = objc_allocateClassPair(original, subclassName.UTF8String, 0);
            if (!subclass) return;
            for (NSString *method in @[@"touchesBeganWithEvent:", @"touchesMovedWithEvent:",
                                       @"touchesEndedWithEvent:", @"touchesCancelledWithEvent:"]) {
                class_addMethod(subclass, NSSelectorFromString(method), (IMP)touchEvent, "v@:@");
            }
            objc_registerClassPair(subclass);
        }
        object_setClass(view, subclass);
    }
    view.allowedTouchTypes |= NSTouchTypeMaskIndirect;
}

int ou_pinch_start(void) {
    for (NSWindow *window in NSApp.windows) attach(window.contentView);
    if (monitor) return 1;
    windowObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil
        usingBlock:^(NSNotification *notification) {
            attach(((NSWindow *)notification.object).contentView);
        }];
    monitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskMagnify
        handler:^NSEvent *(NSEvent *event) {
            attach(event.window.contentView);
#ifdef OPENUTAU_PINCH_DEBUG
            FILE *log = fopen("/tmp/openutau-pinch-axis-debug.log", "a");
            if (log) { fprintf(log, "magnify axis=%d\n", axis); fclose(log); }
#endif
            return event;
        }];
    return monitor != nil;
}
