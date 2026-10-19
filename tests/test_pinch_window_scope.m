#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#include <assert.h>
#include <stdio.h>

#include "../native/openutau_pinch_axis.m"

@interface AvnView : NSView
@property NSInteger probe;
@end
@implementation AvnView @end
@interface AvnWindow : NSWindow @end
@implementation AvnWindow @end
@interface ViewObserver : NSObject @end
@implementation ViewObserver
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {}
@end

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        AvnWindow *editor = [[AvnWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
            styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
        NSView *container = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
        AvnView *canvas = [[AvnView alloc] initWithFrame:container.bounds];
        [container addSubview:canvas];
        editor.contentView = container;
        NSWindow *other = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
            styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
        Class containerClass = object_getClass(container);
        Class otherClass = object_getClass(other.contentView);
        assert(ou_pinch_start());
        assert(object_getClass(container) == containerClass);
        assert(object_getClass(other.contentView) == otherClass);
        assert(strcmp(class_getName(object_getClass(canvas)), "OUTrackpad_AvnView") == 0);
        assert(canvas.allowedTouchTypes & NSTouchTypeMaskIndirect);
        attachWindow(editor);
        assert(strcmp(class_getName(object_getClass(canvas)), "OUTrackpad_AvnView") == 0);

        ViewObserver *observer = [ViewObserver new];
        AvnView *observed = [AvnView new];
        [observed addObserver:observer forKeyPath:@"probe" options:0 context:NULL];
        Class observedClass = object_getClass(observed);
        attach(observed);
        assert(object_getClass(observed) == observedClass);
        [observed removeObserver:observer forKeyPath:@"probe"];

        for (int i = 0; i < 100; i++) {
            @autoreleasepool {
                NSSavePanel *panel = [NSSavePanel savePanel];
                Class panelClass = object_getClass(panel.contentView);
                attachWindow(panel);
                [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidBecomeKeyNotification
                    object:panel];
                assert(object_getClass(panel.contentView) == panelClass);
            }
        }
        assert(ou_pinch_classify(10, 1) == 1);
        assert(ou_pinch_classify(1, 10) == 2);
        assert(ou_pinch_classify(0.1, 0.1) == 0);
        puts("PASS: editor touch capture, unchanged AppKit/KVO classes, 100 save panels, pinch axes");
    }
    return 0;
}
