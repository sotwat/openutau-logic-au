#import <Cocoa/Cocoa.h>

@interface SetupDelegate : NSObject <NSApplicationDelegate>
@property NSWindow *window;
@property NSTextField *status;
@property NSProgressIndicator *progress;
@end

@implementation SetupDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 150)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"OpenUtau・Logic セットアップ";
    self.status = [NSTextField labelWithString:@"OpenUtau・AUプラグイン・中継をインストールしています…"];
    self.status.frame = NSMakeRect(24, 83, 432, 40);
    self.status.lineBreakMode = NSLineBreakByWordWrapping;
    [self.window.contentView addSubview:self.status];
    self.progress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(24, 45, 432, 18)];
    self.progress.indeterminate = YES;
    [self.progress startAnimation:nil];
    [self.window.contentView addSubview:self.progress];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *logs = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs"];
        [[NSFileManager defaultManager] createDirectoryAtPath:logs withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *logPath = [logs stringByAppendingPathComponent:@"OpenUtau-Logic-Setup.log"];
        [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
        NSFileHandle *log = [NSFileHandle fileHandleForWritingAtPath:logPath];
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:@"/bin/sh"];
        task.arguments = @[[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"install.sh"]];
        task.standardOutput = log;
        task.standardError = log;
        NSError *error = nil;
        BOOL launched = [task launchAndReturnError:&error];
        if (launched) [task waitUntilExit];
        [log closeFile];
        BOOL success = launched && task.terminationStatus == 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progress stopAnimation:nil];
            [self.window orderOut:nil];
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = success ? @"セットアップ完了" : @"セットアップを完了できませんでした";
            if (success) {
                alert.informativeText = @"OpenUtau・AUプラグインの登録確認・中継の起動が完了しました。\nLogicが起動中の場合は、プロジェクトを保存して再起動してください。\nLogicの音源スロットでOpenUtau Bridgeを選びます。";
                [alert addButtonWithTitle:@"OpenUtauを開く"];
                [alert addButtonWithTitle:@"閉じる"];
            } else {
                NSString *details = [NSString stringWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:nil] ?: error.localizedDescription ?: @"ログを確認してください。";
                if (details.length > 2400) details = [details substringFromIndex:details.length - 2400];
                alert.informativeText = [NSString stringWithFormat:@"%@\n\nログ：%@", details, logPath];
                [alert addButtonWithTitle:@"ログを開く"];
                [alert addButtonWithTitle:@"閉じる"];
            }
            NSModalResponse result = [alert runModal];
            if (result == NSAlertFirstButtonReturn) {
                NSString *target = success ? [NSHomeDirectory() stringByAppendingPathComponent:@"Applications/OpenUtau AU.app"] : logPath;
                [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:target]];
            }
            [NSApp terminate:nil];
        });
    });
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        SetupDelegate *delegate = [[SetupDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
