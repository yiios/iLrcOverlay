// See http://iphonedevwiki.net/index.php/Logos

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <UIKit/UIKit.h>

#import "./FontLoader/UIFont+WDCustomLoader.h"
#import "./GCDWebServer/GCDWebServer.h"
#import "./GCDWebServer/GCDWebServerDataResponse.h"

NSString* _session = @"";

static UIWindow* _sharedWindow;
static UILabel* _sharedLabel;
static UIFont* _sharedFont;

static bool enabled;
static bool useLandscapeMode;
static NSString* fontFileName;
static CGFloat fontSize = 8;

static void updateUserDefaults(void) {
    
    NSString *bundleId = @"wiki.qaq.DesktopLyricOverlay";
    NSString *plistPath = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", bundleId];
    NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    if (settings[@"Enabled"]) {
        enabled = [settings[@"Enabled"] boolValue];
    } else {
        enabled = true;
    }
    if (settings[@"UseLandscapeMode"]) {
        useLandscapeMode = [settings[@"UseLandscapeMode"] boolValue];
    } else {
        useLandscapeMode = false;
    }
    fontFileName = settings[@"FontFileName"];
    
    NSString* location = [[NSString alloc] initWithFormat:@"/System/Library/Fonts/AppFonts/%@", fontFileName];
    NSURL* target = [NSURL fileURLWithPath:location];
    
    if ([NSFileManager.defaultManager fileExistsAtPath:location]) {
        _sharedFont = [UIFont customFontWithURL:target size:fontSize];
        _sharedFont = [_sharedFont fontWithSize:fontSize];
        [_sharedLabel setFont:_sharedFont];
    } else {
        _sharedFont = [UIFont systemFontOfSize:fontSize];
    }
    if (_sharedLabel) {
        [_sharedLabel setFont: _sharedFont];
    }

}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 {
    
    %orig;
    
    updateUserDefaults();
    
    if (enabled) {
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            if (@available(iOS 11.0, *)) {
                if ([[UIScreen mainScreen] nativeBounds].size.height > 2430) {
                    _sharedWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0,
                                                                               [[UIScreen mainScreen] bounds].size.height - 40,
                                                                               [[UIScreen mainScreen] bounds].size.width,
                                                                               22)];
                }
            }
            if (!_sharedWindow) {
                _sharedWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0,
                                                                           [[UIScreen mainScreen] bounds].size.height - 22,
                                                                           [[UIScreen mainScreen] bounds].size.width,
                                                                           22)];
            }
            fontSize = 8;
        } else {
            _sharedWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       [[UIScreen mainScreen] bounds].size.width,
                                                                       22)];
            fontSize = 14;
        }
        
        _sharedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 22)];
        _sharedFont = [_sharedFont fontWithSize:fontSize];
        [_sharedLabel setFont: _sharedFont];
        
        NSString* welcome = @"👀";
        
        [_sharedLabel setText:welcome];
        [_sharedLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [_sharedLabel setTextColor:[[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.888]];
        [_sharedLabel setBackgroundColor:[[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:0.233]];
        [_sharedLabel setTextAlignment:NSTextAlignmentCenter];
        [_sharedWindow setBackgroundColor:[UIColor clearColor]];
        [_sharedWindow addSubview:_sharedLabel];
        [_sharedWindow setWindowLevel:UIWindowLevelStatusBar + 1];
        _sharedWindow.userInteractionEnabled = NO;
        _sharedWindow.layer.masksToBounds = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if ([_sharedLabel.text isEqualToString:welcome]) {
                [_sharedLabel setHidden:YES];
            }
        });
        
        [_sharedWindow setHidden:NO];
        [_sharedWindow makeKeyAndVisible];
        
        GCDWebServer *_s = [[GCDWebServer alloc] init];
        [_s addDefaultHandlerForMethod:@"GET"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
            
            NSMutableString* base64 = [[[[[request URL] absoluteString] componentsSeparatedByString:@"?"] lastObject] mutableCopy];
            [base64 deleteCharactersInRange:NSMakeRange(0, 6)];
            NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64 options:0];
            NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
            
            if ([decodedString isEqual:@""]) {
                return [GCDWebServerDataResponse responseWithHTML:@"花QQQ"];
            }
            
            updateUserDefaults();
            
            _session = [[NSUUID UUID] UUIDString];
            
            __block NSString* cpy = [decodedString mutableCopy];
            __block NSString* currentSession = [_session mutableCopy];
            dispatch_async(dispatch_get_main_queue(), ^{
                    [_sharedLabel setHidden:NO];
                    [_sharedLabel setText:cpy];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if ([currentSession isEqual:_session]) {
                            [_sharedLabel setHidden:YES];
                        }
                    });
            });
            
            return [GCDWebServerDataResponse responseWithHTML:@"花Q"];
        }];
        [_s startWithPort:6996 bonjourName:nil];
        
    }
    
}
