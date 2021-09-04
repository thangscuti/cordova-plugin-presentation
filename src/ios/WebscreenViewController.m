/*
 * Copyright 2014 Fraunhofer FOKUS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * AUTHORS: Martin Lasak <martin.lasak@fokus.fraunhofer.de>
 */

#import "WebscreenViewController.h"
#import "JointContext.h"
#import "NavigatorPresentation.h"
#import "PresentationSession.h"
#import <WebKit/WebKit.h>
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

@interface WebscreenViewController () <JCWebViewDelegate>

 @property (strong) WKWebView *webView;
 @property (strong) JSContext *ctx;

@end

@implementation WebscreenViewController
GCDWebServer* _webServer;

- (id)initWithSid:(NSString *)sid
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.sid = sid;
        return self;
    }
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Webscreen viewDidLoad");
    NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
    NSLog(@"Visiting %@", _webServer.serverURL);
    if(_webServer.serverURL == nil){
        [self initWebServer:[[NSURL URLWithString:@"public" relativeToURL:bundleURL] absoluteURL]];
    }
   
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"Webscreen viewDidAppear thangnt11");
    NSLog(@"Webscreen viewDidAppear %@", NSStringFromCGSize(self.view.bounds.size));

    if(self.webView){
        return;
    }
//    WKWebViewConfiguration *theConfiguration =
//              [[WKWebViewConfiguration alloc] init];
//        [theConfiguration.userContentController
//              addScriptMessageHandler:self name:@"myApp"];
//
//        _theWebView = [[WKWebView alloc] initWithFrame:self.view.frame
//                          configuration:theConfiguration];
//        [_theWebView loadRequest:request];
//        [self.view addSubview:_theWebView];
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    WKPreferences* preferences =   [[WKPreferences alloc] init];
    preferences.javaScriptEnabled = true;
    theConfiguration.preferences = preferences;
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:theConfiguration];

//    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
//    self.webView.delegate = self;
    self.webView.navigationDelegate = self;
    self.webView.hidden=NO;
    self.webView.autoresizesSubviews = YES;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.webView];
    
   
    
    [self.delegate webscreenReady: self.sid];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void) webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    // Display some error message in case the page to be presented cannot be accessed
    NSString *html = [NSString stringWithFormat:@"<html><body style=\"margin-top: 50%%; background-color: #ffffff; color: #dddddd; font-family: Helvetica; font-size: 48pt; text-align:center; word-wrap: break-word;\">%@<br><span style=\"font-size: 24pt;\">code: %ld</span></body></html>", error.localizedDescription, (long)error.code];

    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"Called WebscreenViewController didReceiveMemoryWarning");
}

- (void)loadUrl:(NSString *)urlAddress
{
    NSLog(@"Called loadUrl: %@", urlAddress);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
         NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
         NSURL *url = [[NSURL URLWithString:@"public" relativeToURL:bundleURL] absoluteURL];
         NSArray *contents = [fileManager contentsOfDirectoryAtURL:url
                               includingPropertiesForKeys:@[]
                                                  options:NSDirectoryEnumerationSkipsHiddenFiles
                                                    error:nil];

         NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension ENDSWITH '.html'"];
         for (NSString *path in contents) {
            // Enumerate each .png file in directory
             NSLog(@"loadUrlThang: %@", path);
         }
    
//    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;
    NSLog(@"Called loadUrl11: %@", bundleURL);
//    NSURL *url = [NSURL URLWithString:@"/board_preview"];
    NSURL *basePath = nil;
    
    basePath = [NSURL URLWithString:@"index.html#board_preview" relativeToURL:_webServer.serverURL];
    NSURLRequest *requestObj = [[NSURLRequest alloc] initWithURL:basePath];
//    NSURL *url = [NSURL URLWithString:urlAddress];
//    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:url];
    // TODO(mla): Second-Screen User_Agent?
//    [requestObj setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36" forHTTPHeaderField:@"User_Agent"];
    [self.webView loadRequest:requestObj];
}
-(void)initWebServer:(NSURL *)basePath {
    NSLog(@"Path::%@", basePath);
   

    // Create server
    _webServer = [[GCDWebServer alloc] init];

    #define GCDWebServer_DEBUG 0
    #define GCDWebServer_VERBOSE 1
    #define GCDWebServer_INFO 2
    #define GCDWebServer_WARNING 3
    #define GCDWebServer_ERROR 4
    #define GCDWebServer_EXCEPTION 5

    [GCDWebServer setLogLevel:GCDWebServer_ERROR];
    // Add a handler to respond to GET requests on any URL
    [_webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {



                                  NSLog([NSString stringWithFormat:@"WS: loading %@", request]);
                                  NSString * page = request.URL.lastPathComponent;
                                  NSString * path = request.URL.path;
                                  NSString * file = path;

                                  NSLog(@"WS: loading %@", file);

                                  NSString * fullPath = [NSString stringWithFormat:@"%@%@", basePath, path];
                                  NSString * sFullPath = [fullPath substringFromIndex:7];

                                  BOOL isText = NO;

                                  if([page.lastPathComponent hasSuffix:@"html"]) {
                                      isText = YES;
                                  }



                                  if (isText) {
                                      NSError * error = nil;
                                      NSString * html = [NSString stringWithContentsOfFile:sFullPath encoding:NSUTF8StringEncoding error: &error];
                                      return [GCDWebServerDataResponse responseWithHTML:html];
                                  }
                                  else {
                                      NSData * data = [NSData dataWithContentsOfFile:sFullPath];
                                      if (data !=nil) {

                                          NSString * type = @"image/jpeg";

                                          if      ([page.lastPathComponent hasSuffix:@"jpg"]) type = @"image/jpeg";
                                          else if ([page.lastPathComponent hasSuffix:@"png"]) type = @"image/png";
                                          else if ([page.lastPathComponent hasSuffix:@"css"]) type = @"text/css";
                                          else if ([page.lastPathComponent hasSuffix:@"js" ]) type = @"text/javascript";


                                          return [GCDWebServerDataResponse responseWithData:data contentType:type];
                                      }
                                      else {

                                          return [GCDWebServerDataResponse responseWithHTML:[NSString stringWithFormat:@"<html><body><p>404 : unknown file %@ World</p></body></html>", sFullPath]];
                                      //return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
                                      }
                                  }
                              }];

    // Start server on port 8080
    [_webServer startWithPort:8080 bonjourName:nil];
    NSLog(@"Visiting %@", _webServer.serverURL);
}

- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"Called webViewDidFinishLoad::%@", self.sid);

    // Now we are good to go to send the deviceready event
//    [self.webView evaluateJavaScript:@"document.dispatchEvent(new Event('deviceready'));" completionHandler:nil];
    [self.ctx evaluateScript:@"document.dispatchEvent(new Event('deviceready'));"];
//    [self.webView callAsyncJavaScript:<#(nonnull NSString *)#> arguments:<#(nullable NSDictionary<NSString *,id> *)#> inFrame:<#(nullable WKFrameInfo *)#> inContentWorld:<#(nonnull WKContentWorld *)#> completionHandler:<#^(id _Nullable, NSError * _Nullable error)completionHandler#>]
    [self.delegate webscreenDidLoadUrl:self.sid];
}

- (void)webView:(WKWebView *)webView didCreateJavaScriptContext:(JSContext *)ctx
{
    NSLog(@"Got context in Webscreen!");
    self.ctx = ctx;

    // Adds javascript bindings
    NavigatorPresentation * pres = [[NavigatorPresentation alloc] initWithSession:self.session];
    ctx[@"navigator"][@"presentation"] = pres;

    // Handles programmatic close request from JavaScript, e.g. window.close()
    ctx[@"close"] = ^ {
        NSLog(@"window close request!");
        [self.delegate webscreenDidClose: self.sid];
    };

}

- (void)closeRequested:(NSString *)sid
{
    [self.delegate webscreenDidClose: sid];
}

- (void)close
{
    [self.webView stopLoading];
    self.view = nil;
    self.webView = nil;
    self.sid = nil;
    self.delegate = nil;
    self.screenId = nil;
}

@end
