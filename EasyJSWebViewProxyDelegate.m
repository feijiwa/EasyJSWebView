//
//  EasyJSWebViewDelegate.m
//  EasyJS
//

#import "EasyJSWebViewProxyDelegate.h"
#import "EasyJSDataFunction.h"
#import <objc/runtime.h>

static NSString* INJECT_JS() {
    static NSString *INJECT_JS = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSData *data = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"easyjs-inject" withExtension:@"js"]];
        INJECT_JS = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    });

    return INJECT_JS;
}

@implementation EasyJSWebViewProxyDelegate

//@synthesize realDelegate;
//@synthesize javascriptInterfaces;

- (void) addJavascriptInterfaces:(NSObject*) interface WithName:(NSString*) name{
    if (! self.javascriptInterfaces){
        self.javascriptInterfaces = [[NSMutableDictionary alloc] init];
    }

    [self.javascriptInterfaces setValue:interface forKey:name];
}

#pragma mark - UIWebViewDelegate
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if (self.realDelegate && [self.realDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.realDelegate webView:(EasyJSWebView *)webView.superview didFailLoadWithError:error];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.realDelegate && [self.realDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.realDelegate webViewDidFinishLoad:(EasyJSWebView *)webView];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSString *requestString = [[request URL] absoluteString];
    if ([requestString hasPrefix:@"easy-js:"]) {
        [self handleRequestString:requestString webView:(EasyJSWebView *)webView.superview];
        return NO;
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    if (self.realDelegate && [self.realDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.realDelegate webViewDidStartLoad:(EasyJSWebView *)webView.superview];
    }

    //inject the basic functions first
    NSString* js = INJECT_JS();
    [webView stringByEvaluatingJavaScriptFromString:js];

    //inject the function interface
    NSString *injection = [self methodsInjectionString];
    [webView stringByEvaluatingJavaScriptFromString:injection];
}

- (void)dealloc{
    if (self.javascriptInterfaces){
        self.javascriptInterfaces = nil;
    }

    if (self.realDelegate){
        self.realDelegate = nil;
    }
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if (self.realDelegate && [self.realDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.realDelegate webView:(EasyJSWebView *)webView.superview didFailLoadWithError:error];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if (self.realDelegate && [self.realDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.realDelegate webView:(EasyJSWebView *)webView.superview didFailLoadWithError:error];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    if (self.realDelegate && [self.realDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.realDelegate webViewDidFinishLoad:(EasyJSWebView *)webView];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *requestString = navigationAction.request.URL.absoluteString;

    if ([requestString hasPrefix:@"easy-js:"]) {
        [self handleRequestString:requestString webView:(EasyJSWebView *)webView.superview];
        decisionHandler(WKNavigationActionPolicyCancel);
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}


- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {

}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    if (self.realDelegate && [self.realDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.realDelegate webViewDidStartLoad:(EasyJSWebView *)webView.superview];
    }

    //inject the basic functions first
    NSString* js = INJECT_JS();
    [webView evaluateJavaScript:js completionHandler:nil];

    //inject the function interface
    NSString *injection = [self methodsInjectionString];
    [webView evaluateJavaScript:injection completionHandler:nil];
}

#pragma mark -
- (NSString *)methodsInjectionString {
    if (! self.javascriptInterfaces){
        self.javascriptInterfaces = [[NSMutableDictionary alloc] init];
    }

    NSMutableString* injection = [[NSMutableString alloc] init];

    //inject the javascript interface
    for(id key in self.javascriptInterfaces) {
        NSObject* interface = [self.javascriptInterfaces objectForKey:key];

        [injection appendString:@"EasyJS.inject(\""];
        [injection appendString:key];
        [injection appendString:@"\", ["];

        Class cls = object_getClass(interface);

        while (cls && ![NSStringFromClass(cls) isEqualToString:NSStringFromClass([NSObject class])]) {
            unsigned int mc = 0;
            Method * mlist = class_copyMethodList(cls, &mc);
            for (int i = 0; i < mc; i++){
                [injection appendString:@"\""];
                [injection appendString:[NSString stringWithUTF8String:sel_getName(method_getName(mlist[i]))]];
                [injection appendString:@"\""];
                [injection appendString:@", "];
            }

            free(mlist);

            cls = class_getSuperclass(cls);
        }

        if ([injection rangeOfString:@", "].location != NSNotFound) {
            [injection deleteCharactersInRange:NSMakeRange(injection.length - 2, 2)];
        }

        [injection appendString:@"]);"];
    }

    return injection;
}

- (void)handleRequestString:(NSString *)requestString webView:(EasyJSWebView *)webView {
    /*
     A sample URL structure:
     easy-js:MyJSTest:test
     easy-js:MyJSTest:testWithParam%3A:haha
     */
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    ////NSLog(@"req: %@", requestString);

    NSString* obj = (NSString*)[components objectAtIndex:1];
    NSString* method = [(NSString*)[components objectAtIndex:2]
                        stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSObject* interface = [_javascriptInterfaces objectForKey:obj];

    // execute the interfacing method
    SEL selector = NSSelectorFromString(method);
    NSMethodSignature* sig = [[interface class] instanceMethodSignatureForSelector:selector];
    NSInvocation* invoker = [NSInvocation invocationWithMethodSignature:sig];
    invoker.selector = selector;
    invoker.target = interface;

    NSMutableArray* args = [[NSMutableArray alloc] init];

    if ([components count] > 3){
        NSString *argsAsString = [(NSString*)[components objectAtIndex:3]
                                  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        NSArray* formattedArgs = [argsAsString componentsSeparatedByString:@":"];
        for (NSInteger i = 0, j = 0, l = [formattedArgs count]; i < l; i+=2, j++){
            NSString* type = ((NSString*) [formattedArgs objectAtIndex:i]);
            NSString* argStr = ((NSString*) [formattedArgs objectAtIndex:i + 1]);

            if ([@"f" isEqualToString:type]){
                EasyJSDataFunction* func = [[EasyJSDataFunction alloc] initWithWebView:webView];
                func.funcID = argStr;
                [args addObject:func];
                [invoker setArgument:&func atIndex:(j + 2)];
            }else if ([@"s" isEqualToString:type]){
                NSString* arg = [argStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [args addObject:arg];
                [invoker setArgument:&arg atIndex:(j + 2)];
            }
        }
    }
    [invoker invoke];

    //return the value by using javascript
    if ([sig methodReturnLength] > 0){
        NSString* retValue;
        [invoker getReturnValue:&retValue];

        if (retValue == NULL || retValue == nil){
            [webView executeJavaScriptFromString:@"EasyJS.retValue=null;"];
        }else{
            retValue = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef) retValue, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
            [webView executeJavaScriptFromString:[@"" stringByAppendingFormat:@"EasyJS.retValue=\"%@\";", retValue]];
        }
    }
}

@end
