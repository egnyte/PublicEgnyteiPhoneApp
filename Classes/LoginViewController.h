//
//  LoginViewController.h
//  egnyteMobilePhone
//
//  Created by Steven Xi Chen on 7/20/10.
//  Copyright 2012 Egnyte Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModalWebViewController.h"

@interface LoginViewController : UIViewController <UIWebViewDelegate,ModalViewDelegate>{
	//input domain view
	IBOutlet UITextField *inputDomainName;
    IBOutlet UIActivityIndicatorView  *loadingSpinner;
	
	//domain validation message label
	IBOutlet UILabel *domainValidityMsg;
	IBOutlet UIButton *signInBtn;
	IBOutlet UILabel *domainLbl;
    IBOutlet UIScrollView *domainScrollView;
    IBOutlet UIButton *linkEgnyteBtn;
    
    NSURLConnection *currentConnection;
    NSMutableData *responseData;
}

- (IBAction) checkDomainValidity;
- (void) processStatusCode: (NSNumber*) statusCodeObj;
- (void) saveDomainAsDefault :(NSString*)actualDomain;
-(void)showSignInOptions;
-(void)hideSignInOptions;
-(IBAction)LinkToEgnyte:(id)sender;
@end
