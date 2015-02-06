//
//  DetailViewController.h
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 3/29/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import "egnyteMobilePadAppDelegate.h"
#import "UploadHandler.h"

@class DomainPlistHandler;
@class RootViewController;


extern NSString *versionFileEntryId;
extern NSString *parentPerm;


@interface DetailViewController : UIViewController <UIActionSheetDelegate,UIDocumentInteractionControllerDelegate,UIWebViewDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate> {
	
	NSFileHandle *fileHandler;
    NSManagedObject *detailItem;
    
	IBOutlet UILabel *unsupportedFileLabel;
    
    RootViewController *rootViewController;
	
	UIPopoverController *RootPopoverController;//pointer for rootpopover, no other way to remove it /w multiple buttons
	UIPopoverController *popoverController;
    
    IBOutlet UILabel *loadingText;
	IBOutlet UIWebView *documentWebview;
	
	NSMutableData *responseData;//NSURLConnection response
	float filesize;
	IBOutlet UIActivityIndicatorView  *loadingSpinner;
	IBOutlet UIProgressView *progressView;
    
	NSURLConnection *currentConnection;
	IBOutlet UIImageView *itemLoadingDialogBox;
}

-(void) getDetailItemFromServer;
-(BOOL) loadDetailItem;

-(void) initHiddenVariables;

@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;
@property (nonatomic, retain) NSURLConnection *currentConnection;
@property (nonatomic, retain) UIWebView *documentWebview;

@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSManagedObject *detailItem;
@property (nonatomic, assign) float filesize;




@end
