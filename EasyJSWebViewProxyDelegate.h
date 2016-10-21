//
//  EasyJSWebViewDelegate.h
//  EasyJS
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@class EasyJSWebView;

@protocol EasyJSWebViewDelegate <NSObject>

@optional
- (void)webView:(EasyJSWebView *)webView didFailLoadWithError:(NSError *)error;
- (void)webViewDidStartLoad:(EasyJSWebView *)webView;
- (void)webViewDidFinishLoad:(EasyJSWebView *)webView;

@end

@interface EasyJSWebViewProxyDelegate : NSObject<UIWebViewDelegate, WKNavigationDelegate>

@property (nonatomic, strong) NSMutableDictionary* javascriptInterfaces;
@property (nonatomic, weak) id<EasyJSWebViewDelegate> realDelegate;

- (void) addJavascriptInterfaces:(NSObject*) interface WithName:(NSString*) name;

@end
