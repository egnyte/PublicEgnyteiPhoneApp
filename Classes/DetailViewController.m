//
//  DetailViewController.m
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 2/16/11.
//  Copyright 2011 Egnyte Inc. All rights reserved.
//

#import "RootViewController.h"
#import "DetailViewController.h"
#import "DomainPlistHandler.h"

#import "Utilities.h"
#import "Constants.h"
#import "ModalWebViewController.h"
NSString *parentPerm = @"";
@implementation DetailViewController

@synthesize rootViewController;
@synthesize detailItem;
@synthesize documentWebview, filesize;
@synthesize currentConnection;
@synthesize responseData;

#pragma mark -
#pragma mark Managing the detail item

//set Deatil Item file object to be loaded on Webview
- (void)setDetailItem:(NSManagedObject *)managedObject {
    
	if (managedObject != nil) {
		itemLoadingDialogBox.hidden = YES;
		[loadingSpinner startAnimating];
		[detailItem release];
        detailItem = nil;
        
		if (detailItem != managedObject) { //new object
            
			detailItem = [managedObject retain];
			
            [self getDetailItemFromServer];
            progressView.progress = 0;
            progressView.hidden = NO;
            itemLoadingDialogBox.hidden = NO;
            
		} else {
            [self getDetailItemFromServer];
            progressView.hidden = NO;
            progressView.progress = 0;
            itemLoadingDialogBox.hidden = NO;
		}
    } else {
        [detailItem release];
        detailItem = nil;
    }
    
}


- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    
	self.currentConnection = connection;
	
	return request;
}

//get file from cloud HTTP request
- (void)getDetailItemFromServer {
    
	NSURL *url = [Utilities getFileByPathURL:[detailItem valueForKey:@"path"]];
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url
														 cachePolicy:NSURLRequestUseProtocolCachePolicy
													 timeoutInterval:REQUEST_TIMEOUT];
    
    
    
    [Utilities setUniversalGETRequestHeaders:request];
    
	[loadingSpinner startAnimating];
	self.currentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    
    
	int statusCode = [((NSHTTPURLResponse *)response) statusCode];
	if (statusCode==304) {
        //local file is the most up to date version
		itemLoadingDialogBox.hidden = YES;
		progressView.hidden = YES;
		[self loadDetailItem];
		[connection cancel];
		
	} else if (statusCode==200) {
        
        
        NSDictionary *allHeaders = [((NSHTTPURLResponse *)response) allHeaderFields];
        if([allHeaders objectForKey:@"Content-Length"] != nil)
            self.filesize = [[allHeaders valueForKey:@"Content-Length"] floatValue];
        else
            self.filesize = [response expectedContentLength];
        
        if(detailItem != nil) {
			//get item's path.
			NSString *itemPath = [detailItem valueForKey:@"path"];
            NSString *filePath;
            
            [Utilities createParentDirectoryForPath:itemPath];
            filePath = [[Utilities applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",[DomainPlistHandler getDomainFromPlist],[detailItem valueForKey:@"path"]]];
            //create downloading file in application directory
			[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
			
			[fileHandler release];
			fileHandler = [[NSFileHandle fileHandleForUpdatingAtPath:filePath] retain];
			
			if (fileHandler)
				[fileHandler seekToEndOfFile];
		}
        
	} else {
        //get file failed
        rootViewController.rootTableView.allowsSelection = YES;
        rootViewController.rootTableView.alpha = 1.0f;
		progressView.hidden = YES;
		[loadingSpinner stopAnimating];
        itemLoadingDialogBox.hidden = YES;
        [Utilities processStatusCode:statusCode];
		if (self.currentConnection != nil) {
            [self.currentConnection cancel];
            self.currentConnection = nil;
		}
        
		return;
	}
	
	//can not be reused if this is not reinitalized
    self.responseData = [[NSMutableData alloc]init];
    
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    //data received for downloading file
	if ([data length]!=0) {
		[self.responseData appendData:data];
		
		if (fileHandler) {
			[fileHandler seekToEndOfFile];
			
			[fileHandler writeData:data];
            //show progress of file download
			float resourceLength = [self.responseData length];
			progressView.progress = resourceLength/self.filesize;
		}
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //file download HTTP request failed
    
    if (self.currentConnection != nil) {
        [self.currentConnection release];
        self.currentConnection = nil;
    }
    
    [responseData setLength:0];
    [Utilities showAlertViewWithTitle:[NSString stringWithFormat:@"Connection timed out (%d) ",error.code] withMessage:@"Please try again later." delegate:nil];
    rootViewController.rootTableView.allowsSelection = YES;
    rootViewController.rootTableView.alpha = 1.0;
	itemLoadingDialogBox.hidden = YES;
	progressView.hidden = YES;
	[loadingSpinner stopAnimating];
    detailItem = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [responseData setLength:0];
    [responseData release];
	itemLoadingDialogBox.hidden = YES;
	progressView.hidden = YES;
	
    // Once this method is invoked, "responseData" contains the complete result
	if(detailItem != NULL && [[detailItem valueForKey:@"isFolder"] intValue] == 0) {
        [self loadDetailItem]; //load downloaded file on webview
	}
    
    
    if (self.currentConnection != nil) {
        [self.currentConnection release];
        self.currentConnection = nil;
    }
    
    [rootViewController refreshDir];
	[fileHandler closeFile];
    [loadingSpinner stopAnimating];
}

- (BOOL) loadDetailItem{
	
    //load detail Item file on Webview
	unsupportedFileLabel.hidden = YES;
    
    if ([self.documentWebview isLoading]) {
		[self.documentWebview stopLoading];
    }
    
    NSString *displayedDomain = [DomainPlistHandler getDomainFromPlist];
    NSString *filePath;
    
    filePath = [[Utilities applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",displayedDomain,[detailItem valueForKey:@"path"]]];
    
    
	NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:fileURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    [sharedCache release];
    sharedCache = nil;
    [self.documentWebview loadRequest:request];
    
	[fileURL release];
	return YES;
}


#pragma mark -
#pragma mark Managing the detail item


#pragma mark -
#pragma mark UIWebView delegate methods
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    if (request.mainDocumentURL.relativePath == nil) {
        return YES; //to complete loading about:blank page on change domain
    } else if (detailItem == nil) { //clear when detailItem = nil
		self.title = @"";
		return YES;
	}
	
	self.title = [detailItem valueForKey:@"name"];
	loadingText.hidden = NO;
	loadingText.text = @"Loading...";
    itemLoadingDialogBox.hidden = NO;
	if([detailItem valueForKey:@"egnyteID"] != nil) {
        [loadingSpinner startAnimating]; //webview takes some time to load file,spinner stopped on webview finish loading
    }
	
	return YES;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [loadingSpinner stopAnimating];
    loadingText.hidden = YES;
    itemLoadingDialogBox.hidden = YES;
    rootViewController.rootTableView.alpha = 1.0;
    if ([error code] == 204) {//can't load file
        
    }
    if ([error code] == 102) {//can't load file
        unsupportedFileLabel.hidden = NO;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView{
	if([aWebView request ].mainDocumentURL.relativePath != nil) {
		self.documentWebview.hidden = NO;
		[loadingSpinner stopAnimating];
		loadingText.hidden = YES;
        itemLoadingDialogBox.hidden = YES;
		progressView.hidden = YES;
		rootViewController.rootTableView.alpha = 1.0;
	}
}


#pragma mark -
#pragma mark Rotation support
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return YES;
}


#pragma mark -
#pragma mark View lifecycle

-(void)initHiddenVariables{
	loadingText.hidden = YES;
	self.documentWebview.hidden = YES;
}


- (void)viewDidAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
	[super viewDidAppear:animated];
	loadingText.hidden = YES;
}

//Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
	[super viewDidLoad];
    
	[self initHiddenVariables];
	
	self.title = @"";
    self.documentWebview.dataDetectorTypes = UIDataDetectorTypeLink;
    self.documentWebview.delegate = self;
    
}


@end