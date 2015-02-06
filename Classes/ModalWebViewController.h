//
//  ModalWebViewController.h
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 6/30/10.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
@protocol ModalViewDelegate <NSObject>
- (void)userFinishedOAuthLogin:(int)statusCode;
@end

@interface ModalWebViewController : UIViewController <UIWebViewDelegate>{
	id <ModalViewDelegate> delegate;
	
	IBOutlet UIWebView *modalWebView;
    IBOutlet UIActivityIndicatorView *loadingSpinner;
    
    NSString *ssoDomain;
    NSString *ssoUsername;
}

- (void) modalWebViewGoBack;
- (void) toOAuthLogin;

@property (nonatomic, retain) NSString *ssoDomain;
@property (nonatomic, retain) NSString *ssoUsername;
@property (nonatomic, assign) id <NSObject, ModalViewDelegate > delegate;
@end
