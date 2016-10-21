//
//  EasyJSDataFunction.h
//  EasyJSWebViewSample
//

#import <Foundation/Foundation.h>
#import "EasyJSWebView.h"

@interface EasyJSDataFunction : NSObject

@property (nonatomic, strong) NSString* funcID;
@property (nonatomic, strong) EasyJSWebView* webView;
@property (nonatomic, assign) BOOL removeAfterExecute;

- (id) initWithWebView: (EasyJSWebView*) _webView;

- (NSString*) execute;
- (NSString*) executeWithParam: (NSString*) param;
- (NSString*) executeWithParams: (NSArray*) params;

@end
