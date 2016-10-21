//
//  EasyJSWebView.m
//  EasyJS
//

#import "EasyJSWebView.h"

#define iOSVersionGreaterThanOrEqualTo(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface EasyJSWebView ()
@property (nonatomic, strong) id webView;
@property (nonatomic, strong) EasyJSWebViewProxyDelegate* proxyDelegate;
@end

@implementation EasyJSWebView

@synthesize proxyDelegate;
- (id)init{
    self = [super init];
    if (self) {
        if(iOSVersionGreaterThanOrEqualTo(@"8.0.0")) {
            WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
            self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        }
        else {
            self.webView = [[UIWebView alloc] init];
        }
        [self addSubview:self.webView];

        WS(weakSelf);
        [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(weakSelf);
        }];

        [self initEasyJS];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];

    if (self){
        [self initEasyJS];
    }

    return self;
}

- (void) dealloc{
    self.proxyDelegate = nil;
    self.delegate = nil;
    [self stopLoading];

    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    [self cleanForDealloc];
}

- (void) initEasyJS{
    EasyJSWebViewProxyDelegate *delegate = [[EasyJSWebViewProxyDelegate alloc] init];
    self.proxyDelegate = delegate;

    if ([self.webView isKindOfClass:[UIWebView class]]) {
        UIWebView *webView = (UIWebView *)self.webView;
        webView.delegate = self.proxyDelegate;
    }
    else {
        WKWebView *webView = (WKWebView *)self.webView;
        webView.navigationDelegate = self.proxyDelegate;
    }
}

- (void) setDelegate:(id<EasyJSWebViewDelegate>)delegate{
    self.proxyDelegate.realDelegate = delegate;
}

- (void) addJavascriptInterfaces:(NSObject*) interface WithName:(NSString*) name{
    [self.proxyDelegate addJavascriptInterfaces:interface WithName:name];
}

#pragma mark -

- (void)loadRequest:(NSURLRequest *)request {
    if ([self.webView respondsToSelector:@selector(loadRequest:)]) {
        [self.webView performSelector:@selector(loadRequest:) withObject:request];
    }
}

- (void)stopLoading {
    if ([self.webView respondsToSelector:@selector(stopLoading)]) {
        [self.webView performSelector:@selector(stopLoading)];
    }
}

- (void)cleanForDealloc {
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        UIWebView *webview = (UIWebView *)self.webView;
        [webview stopLoading];
        webview.delegate = nil;
        [webview removeFromSuperview];
        [webview loadHTMLString:@"" baseURL:nil];
    }
    else {
        WKWebView *webview = (WKWebView *)self.webView;
        [webview stopLoading];
        webview.navigationDelegate = nil;
        [webview removeFromSuperview];
        [webview loadHTMLString:@"" baseURL:nil];
    }
}

//execute the JS and wait for a response
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script error:(NSError **)error {
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        return [(UIWebView *)self.webView stringByEvaluatingJavaScriptFromString:script];
    }
    else {
        __block NSString *resultString = @"";
        __block BOOL finished = NO;
        __block NSError *tmpError = nil;

        [(WKWebView *)self.webView evaluateJavaScript:script completionHandler:^(id result, NSError *jsError) {
            if (jsError == nil) {
                if (result != nil) {
                    resultString = [NSString stringWithFormat:@"%@", result];
                }
            } else {
                tmpError = [jsError copy];
            }
            finished = YES;
        }];

        //max 5 seconds for script to run
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:5];

        while (!finished && [[NSDate date] compare:date] == NSOrderedAscending){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }

        if (!finished) {
            NSLog(@"Timed out");
        }


        if (tmpError && error != NULL) {
            *error = [tmpError copy];
        }

        return resultString;
    }
}

//just execute the JS, dont wait for a response
- (void)executeJavaScriptFromString:(NSString *)script {
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        [self stringByEvaluatingJavaScriptFromString:script error:nil];
    }
    else {
        [(WKWebView *)self.webView evaluateJavaScript:script completionHandler:nil];
    }
}

- (void)goBack {
    if ([self.webView respondsToSelector:@selector(goBack)]) {
        [self.webView performSelector:@selector(goBack)];
    }
}
- (void)goForward {
    if ([self.webView respondsToSelector:@selector(goForward)]) {
        [self.webView performSelector:@selector(goForward)];
    }
}


- (BOOL)canGoBack {
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        return [(UIWebView *)self.webView canGoBack];
    }
    else {
        return [(WKWebView *)self.webView canGoBack];
    }
}


- (UIScrollView *)scrollView {
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        return [(UIWebView *)self.webView scrollView];
    }
    else {
        return [(WKWebView *)self.webView scrollView];
    }
}

@end
