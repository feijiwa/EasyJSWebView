//
//  EasyJSDataFunction.m
//  EasyJSWebViewSample
//

#import "EasyJSDataFunction.h"

@implementation EasyJSDataFunction

@synthesize funcID;
@synthesize webView;
@synthesize removeAfterExecute;

- (id) initWithWebView:(EasyJSWebView *)_webView{
    self = [super init];
    if (self) {
        self.webView = _webView;
    }
    return self;
}

- (NSString*) execute{
    return [self executeWithParams:nil];
}

- (NSString*) executeWithParam: (NSString*) param{
    NSMutableArray* params = [[NSMutableArray alloc] initWithObjects:param, nil];
    return [self executeWithParams:params];
}

- (NSString*) executeWithParams: (NSArray*) params{
    NSMutableString* injection = [[NSMutableString alloc] init];

    [injection appendFormat:@"EasyJS.invokeCallback(\"%@\", %@", self.funcID, self.removeAfterExecute ? @"true" : @"false"];

    if (params){
        for (NSInteger i = 0, l = params.count; i < l; i++){
            NSString* arg = [params objectAtIndex:i];

            NSString* encodedArg = (NSString*) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)arg, NULL, (CFStringRef) @"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));

            [injection appendFormat:@", \"%@\"", encodedArg];
        }
    }

    [injection appendString:@");"];

    if (self.webView){
        return [self.webView stringByEvaluatingJavaScriptFromString:injection error:nil];
    }else{
        return nil;
    }
}

@end
