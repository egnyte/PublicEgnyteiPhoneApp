//
//  ModalWebViewController.m
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 6/30/10.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//
#import "Constants.h"
#import "ModalWebViewController.h"
#import "DomainPlistHandler.h"
#import "JSON.h"
#import "Utilities.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation ModalWebViewController
@synthesize delegate;
@synthesize ssoDomain, ssoUsername;

//back button action
-(void)modalWebViewGoBack{
	[modalWebView goBack];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    loadingSpinner.layer.shadowColor = [UIColor grayColor].CGColor;
    loadingSpinner.layer.shadowRadius = 1;
    loadingSpinner.layer.shadowOpacity = 0.3;
    loadingSpinner.layer.shadowOffset = CGSizeMake(0, 1);
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
											   target:self
											   action:@selector(dismissModalView)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(modalWebViewGoBack)] autorelease];
	self.navigationItem.leftBarButtonItem.enabled = NO;
    if ([self.title isEqualToString:@"OAuth Login"]) {
		[self toOAuthLogin];
	}
    
	
}

- (void)dismissModalView {
	NSString *urlAddress =[NSString stringWithFormat:@"about:blank"];
	NSURL *mediaPath = [NSURL URLWithString:urlAddress];
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:mediaPath];
	[modalWebView loadRequest:requestObj];
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

//Load OAuth Login Screen
- (void) toOAuthLogin {
    
    NSURL *ssoPath = [Utilities getMobileOAuthURL:ssoDomain];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:ssoPath];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [DomainPlistHandler writeDomainToPlist:[NSString stringWithFormat:@"%@.%@.com",ssoDomain,CONST_APP_SERVER_NAME]];
    [modalWebView loadRequest:request];
}

-(void)loadURLFromRequest:(id)sender{
	modalWebView.delegate = self;
}

#pragma mark UIWebView delegate methods
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
	[loadingSpinner startAnimating];
	self.navigationItem.leftBarButtonItem.enabled = YES;
	NSString *requestAbsString = [[request URL]absoluteString];
    NSRange OAuthResp = [requestAbsString rangeOfString:@"access_token"];
    NSRange OAuthAccessDenied = [requestAbsString rangeOfString:@"access_denied"];
    NSRange OauthLoginURL = [requestAbsString rangeOfString:@"/puboauth/token"];
	NSLog(@"requestAbsString:%@",requestAbsString);
    if(OauthLoginURL.location != NSNotFound) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
    } else if([requestAbsString isEqualToString:@"about:blank"] && (![request.mainDocumentURL.relativePath isEqualToString:@"/mobile"]|| ![request.mainDocumentURL.relativePath isEqualToString:@"/i-phone"])) {
		//disable back button when blank error page loaded on network unavailable
		self.navigationItem.leftBarButtonItem.enabled = NO;
	} else if(OAuthResp.location != NSNotFound) {
        //SSO LOGIN STEP 2 grab access token & token type out of URL
        //syntax https://www.egnyte.com/#access_token=tqd6gddjv637taa8hgf2cgjy&token_type=bearer
        
        NSDictionary *urlParams = [Utilities parseNSURLParameters:request.mainDocumentURL];
        
        [DomainPlistHandler writeOAuthTokenType:[urlParams objectForKey:@"token_type"]];
        [DomainPlistHandler writeAccessTokenToPlist:[urlParams objectForKey:@"access_token"]];
        [delegate userFinishedOAuthLogin:200];
        [self dismissModalViewControllerAnimated:NO];
        
        return NO;
    }else if(OAuthAccessDenied.location != NSNotFound) {
        //OAuth Access Denied
        [Utilities showAlertViewWithTitle:@"OAuth failed" withMessage:@"Access denied" delegate:nil];
        [loadingSpinner stopAnimating];
        [self dismissModalViewControllerAnimated:NO];
        return NO;
    }
    
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
	[loadingSpinner stopAnimating];
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [loadingSpinner stopAnimating];
    //load error page on Webview in case of failure
    if(error.code == -1001 || error.code == -1004 || error.code == -1003 ){
        self.navigationItem.leftBarButtonItem.enabled = NO;
		NSString* errorString = [NSString stringWithFormat:
								 @"<html><center><font size=+3 color='red'>An error occurred:<br>%@</font></center></html>",
								 error.localizedDescription];
		if ([self.title isEqualToString:@"OAuth Login"]) {
            [Utilities showAlertViewWithTitle:@"SSO failed" withMessage:@"Please check your login information then try again" delegate:nil];
        }
        [modalWebView loadHTMLString:errorString baseURL:nil];
	} else {
        self.navigationItem.leftBarButtonItem.enabled = NO; //cant goBack on network failed
		NSString* errorString = [NSString stringWithFormat:
								 @"<html><center><font size=+3 color='red'>An error occurred:<br>%@</font></center></html>",
								 error.localizedDescription];
		if ([self.title isEqualToString:@"OAuth Login"])
            [modalWebView loadHTMLString:errorString baseURL:nil];
	}
    
}
#pragma mark -
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)dealloc {
    [modalWebView setDelegate:nil];
    [modalWebView stopLoading];
    [super dealloc];
}


@end
