//
//  RootViewController.h
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 2/16/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "JSON.h"
#import "Constants.h"
#import <CommonCrypto/CommonDigest.h>
#import "UploadHandler.h"
#import "CustomTableCell.h"
#import "DetailViewController.h"
#import "FolderBrowserViewController.h"
#import "LoginViewController.h"

@interface RootViewController : UIViewController <UISearchBarDelegate,FileUploadDelegate,UINavigationControllerDelegate, UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate,UIAlertViewDelegate, UIImagePickerControllerDelegate,UITextFieldDelegate,FolderBrowserViewDelegate> {
    
    DetailViewController *detailViewController;
	BOOL showingImagePicker;
	
    IBOutlet UITableView *rootTableView;
	IBOutlet UIActivityIndicatorView  *loadingSpinner;
    NSFetchedResultsController *fetchedResultsController;
    NSManagedObjectContext *managedObjectContext;
	NSMutableData *responseData;//NSURLConnection response
	
    
	//userinfo. changed on welcomeViewController and "Change Domain" under settings view controller
	NSString *domainName;
	NSString *username;
	
	id *rootDelegate;
	NSString *currentPID;
	NSString *currentAbsolutePath;
	NSManagedObject *currentObject;
	BOOL inEditMode;
	
	UIImage *selectedImage;
	UIImage *unselectedImage;
	NSString *folderName;
	
	IBOutlet UITextField *folderNewNameTextField;
	IBOutlet UIToolbar *newNameToolbar;
	BOOL createNewFolder;
	
	IBOutlet UILabel *rootViewToastMsg;
	
	// new bar button
	IBOutlet UIBarButtonItem *uploadBtn;
    IBOutlet UIBarButtonItem *newFolderBtn;
    IBOutlet UIToolbar *createNewOrActionOptionToolbar;
	//action bar button
	IBOutlet UIBarButtonItem *actionButton;
    IBOutlet UIToolbar *bottomNavBar;
    IBOutlet UIBarButtonItem *saveFolderButton;
    IBOutlet UILabel *uploadingLbl;
    IBOutlet UIImageView *itemLoadingDialogBox;
	int folderCheckedCnt;
    int fileCheckedCnt;
	
	Boolean creatingNewFolder;
    
	NSURLConnection *currentConnection;
	UINavigationController *rootViewNavigationController;
	
	NSMutableArray *selectedRowArray;
    
	CGFloat animatedDistance; //textfield correction when keyboard is out
	
    UIImagePickerController *imagePicker;
    BOOL isChangingMediaToUpload;
    
}

@property (nonatomic, retain) UIBarButtonItem *moreButton;

@property(assign) BOOL createNewFolder;

@property (nonatomic, retain) NSURLConnection *currentConnection;

@property (nonatomic, assign) BOOL showingImagePicker;
@property (nonatomic, retain) UINavigationController *rootViewNavigationController;
@property (nonatomic, retain) IBOutlet UIToolbar *newNameToolbar;
@property (nonatomic, retain) NSString *domainName;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) DetailViewController *detailViewController;
@property (nonatomic, retain) UITableView *rootTableView;
@property (nonatomic, retain) NSString *folderName;

@property (nonatomic, retain) NSString *currentPID;
@property (nonatomic, retain) NSString *currentAbsolutePath;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, assign) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSManagedObject *currentObject;
@property (nonatomic, retain) NSMutableArray *selectedRowArray;
@property (nonatomic, retain) UIImage *selectedImage;
@property (nonatomic, retain) UIImage *unselectedImage;
@property (nonatomic, retain) UIBarButtonItem *uploadBtn;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *actionButton;
@property (nonatomic, retain) IBOutlet UIToolbar *bottomNavBar;

@property BOOL inEditMode;
@property (nonatomic,retain) IBOutlet UILabel *rootViewToastMsg;
@property (nonatomic,retain) IBOutlet UIToolbar *createNewOrActionOptionToolbar;
@property   (assign) int folderCheckedCnt;
@property   (assign) int fileCheckedCnt;

@property (nonatomic, retain) IBOutlet UITextField *folderNewNameTextField;


#pragma mark Initialization methods -
- (id) initTableWithDelegate:(NSString *)cPID path:path;
- (void) initDomainPlist;
- (void) initImagePicker;
- (void)initContextAndFetchController;
- (void)initRoot:(id)sender;
- (void)initVars;
- (void) initDetailViewController;
- (void)initializeSelectedRowArray;
- (IBAction) useMediaPicker:(id) sender;
- (IBAction) newFolderAction;
-(void) refreshDir;
-(void)showUploadingIndicator;
-(void)hideUploadingIndicator;
#pragma mark -

- (void) toLoginView;

- (CustomTableCell *) configFileRowFormat:(NSString *)cellIdentifier;
- (CustomTableCell *) configFolderRowFormat:(NSString *)cellIdentifier;
- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath managedObj:(NSManagedObject *)managedObject;

- (void)processObject:(NSArray *)item pid:(NSString *)PID currAbsPath:(NSString*)currAbsPath isFolder:(int)isFolder alreadyInLocalDb:(BOOL)alreadyInLocalDb localDbItem:(NSManagedObject *)localItem;

- (void) getDirectoryFromServer:(NSString *)path;
- (void) browseToNextDepth;
- (BOOL) processFreshDirectoryJSON:(NSDictionary *)parsedJSON PID:(NSString*)folderPID currAbsPath:(NSString*)currAbsPath mObjContext:(NSManagedObjectContext*)mObjContext;

- (void)conditionallyShowingActionButtons:(NSString*)currAbsPath objectCnt:(NSManagedObjectContext*)mCntxt;
- (BOOL) loadDirectory:(NSString *)PID;
- (void) reloadData;

- (void) deleteFileFromFS:(NSString *)physicalFilePath;
-(BOOL)deleteRowPermanently:(NSIndexPath *)indexPath;


- (BOOL)createFolder: (NSString *)folderName;
- (void)newFolderAction;
- (IBAction)removeNewFolderBar;
- (IBAction)saveFolder:(id)sender;

-(IBAction)toggleFileOrFolderAction;
//new actions added for deletion
- (void)deleteBtnListener;
-(void)useMediaPicker:(id) sender;

- (void)enableBottomToolBarActions;


- (int)deleteSelectedFileOrFolderForPath:(NSString *)path egnyteId:(NSString*)egnyteId isFolder:(int)isFolder;


-(NSManagedObject*)createNewFolderInCoreDBWithName:(NSString*)folderName withPID:(NSString*)folderPID serverPath:(NSString*)absolutePath objContext:(NSManagedObjectContext*)mObjContext;

-(void)deleteRowFromCoreDB:(NSManagedObject*)objToDelete atIndexPath:(NSIndexPath*)mSelectedIndexPath;

-(void)cleanOffDetailViewBasedOnDeletedObj:(NSManagedObject*)deletedObj;
- (IBAction)userLogout;
- (void)dismissModalView;
@end
