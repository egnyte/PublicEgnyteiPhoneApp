//
//  LoginViewController.m
//  egnyteMobilePhone
//
//  Created by Steven Xi Chen on 7/20/10.
//  Copyright 2012 Egnyte Inc. All rights reserved.
//

#import "LoginViewController.h"
#import "JSON.h"
#import "Utilities.h"

@implementation LoginViewController

//used to enable or disable Login button
- (void)updateLabelUsingContentsOfTextField:(id)sender{
    NSString *trimmedDomainName = [inputDomainName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![trimmedDomainName isEqualToString:@""]){
        signInBtn.enabled = YES;
    } else
        signInBtn.enabled = NO;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
-(IBAction)LinkToEgnyte:(id)sender {
    [self showSignInOptions];
}
//For OAuth Login
-(void) checkDomainValidity {
    ModalWebViewController *OAuthLogin = [ModalWebViewController alloc];
    OAuthLogin.delegate = self;
    OAuthLogin.title = @"OAuth Login";
    OAuthLogin.ssoDomain = inputDomainName.text;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:OAuthLogin];
    navController.modalPresentationStyle = UIModalPresentationPageSheet;
    
    [self presentModalViewController:navController animated:YES];
    
    [OAuthLogin release];
    [navController release];
}
-(void)showSignInOptions {
    //show Sign In Options
    linkEgnyteBtn.hidden = YES;
    linkEgnyteBtn.userInteractionEnabled = NO;
    
    signInBtn.hidden = NO;
    signInBtn.userInteractionEnabled = YES;
    
    inputDomainName.hidden = NO;
    inputDomainName.autocorrectionType =  UITextAutocorrectionTypeNo;
	[inputDomainName addTarget:self action:@selector(updateLabelUsingContentsOfTextField:) forControlEvents:UIControlEventEditingChanged];
    inputDomainName.userInteractionEnabled = YES;
    
}
-(void)hideSignInOptions {
    //hide Sign In & show Link To Egnyte button
    linkEgnyteBtn.hidden = NO;
    linkEgnyteBtn.userInteractionEnabled = YES;
    
    signInBtn.hidden = YES;
    signInBtn.userInteractionEnabled = NO;
    
    inputDomainName.hidden = YES;
    inputDomainName.userInteractionEnabled = NO;
}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    //show Link To Egnyte on Startup
    [self hideSignInOptions];
    
	NSString *userDomain = [DomainPlistHandler getDomainFromPlist];
	if (![userDomain isEqualToString:@""] && ![userDomain isEqualToString:@"yourdomain"]) {
		inputDomainName.text = [DomainPlistHandler getDomainFromPlist];
	}
    [domainScrollView setContentSize:CGSizeMake(self.view.frame.size.width,550)];
}
//used to validate user login
-(void) getDirectoryFromServer:(NSString *)domainName  {
    
    [signInBtn setEnabled:NO];
    
    [loadingSpinner startAnimating];
    domainValidityMsg.hidden = NO;
    domainValidityMsg.textColor = [UIColor whiteColor];
    domainValidityMsg.text = @"Connecting...";
    //1) get new snapshot to validate domain
    
    NSString *encodedURLString = [[NSString stringWithFormat:@"https://%@/pubapi/v1/fs/?list_content=true",domainName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:encodedURLString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
                                                           cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval: REQUEST_TIMEOUT];
    [Utilities setUniversalGETRequestHeaders:request];
    [[NSURLConnection alloc]initWithRequest:request delegate:self];
    
    
}
#pragma mark
#pragma mark NSURLConnection delegates



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	int statusCode = [((NSHTTPURLResponse *)response) statusCode];
    
    if(statusCode == 200){
        //successful login
        [self dismissModalViewControllerAnimated:NO];
    } else {
        //failure login
        [signInBtn setEnabled:YES];
        [self performSelectorOnMainThread:@selector(processStatusCode:) withObject:[NSNumber numberWithInt:statusCode] waitUntilDone:NO];
    }
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    connection = nil;
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [signInBtn setEnabled:YES];
    [loadingSpinner stopAnimating];
    domainValidityMsg.text = @"Invalid Login.";
    domainValidityMsg.textColor = [UIColor redColor];
    connection = nil;
}
#pragma mark -

-(void) processStatusCode: (NSNumber*) statusCodeObj {
    int statusCode = [statusCodeObj intValue];
	if (statusCode == 200) {
		[loadingSpinner stopAnimating];
		domainValidityMsg.highlighted = YES;
		
		//domain successful validated
		domainValidityMsg.text = @"Domain Validated.";
		domainValidityMsg.textColor = [UIColor orangeColor];
		
	} else {
		[loadingSpinner stopAnimating];
		if (statusCode == 0 || statusCode == 401 || statusCode == 402 || statusCode == 502) {
			//domain check failed
			domainValidityMsg.text = @"Invalid Login.";
			domainValidityMsg.textColor = [UIColor redColor];
		}else if (statusCode == 503) {
			//Service Temp Unavailable
			domainValidityMsg.text = @"Please try later.";
			domainValidityMsg.textColor = [UIColor redColor];
		}else if (statusCode == 504) {
			//Request Timed out
			domainValidityMsg.text = @"Timed out.";
			domainValidityMsg.textColor = [UIColor redColor];
		}
	}
}
-(void) saveDomainAsDefault :(NSString*)actualDomain{
	NSRange domainNameInputRange;
	NSString *displayedDomain = inputDomainName.text;
	domainNameInputRange = [displayedDomain rangeOfString:[NSString stringWithFormat:@".%@.com",CONST_APP_SERVER_NAME]];
	
	if(domainNameInputRange.location != NSNotFound)
		displayedDomain = [[displayedDomain componentsSeparatedByString:[NSString stringWithFormat:@".%@.com",CONST_APP_SERVER_NAME]]objectAtIndex:0];
    [DomainPlistHandler writeDomainToPlist:inputDomainName.text];
}

#pragma mark -

- (void)dealloc {
	[loadingSpinner release];
    [super dealloc];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES;
}
#pragma mark
#pragma mark ModalViewDelegates method
- (void)userFinishedOAuthLogin:(int)statusCode {
    //Finished OAuth Login
	[loadingSpinner startAnimating];
    signInBtn.enabled = NO;
    
    NSString *domainName = [DomainPlistHandler getDomainFromPlist];
    [self getDirectoryFromServer:domainName];
    
}

@end



