//
//  EasyJSWebView.h
//  EasyJS
//

#import <UIKit/UIKit.h>
#import "EasyJSWebViewProxyDelegate.h"
#import <WebKit/WebKit.h>

@interface EasyJSWebView : UIView

// All the events will pass through this proxy delegate first
@property (nonatomic, weak) id <EasyJSWebViewDelegate> delegate;

- (void)addJavascriptInterfaces:(NSObject*) interface WithName:(NSString*) name;

- (void)loadRequest:(NSURLRequest *)request;
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script error:(NSError **)error;
- (void)executeJavaScriptFromString:(NSString *)script;
- (void)stopLoading;
- (void)cleanForDealloc;
- (void)goBack;
- (void)goForward;
- (BOOL)canGoBack;
@end
