//
//  FolderBrowserViewController.h
//  egnyteMobileIOSUniversal
//
//  Created by Ritika on 26/09/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "DomainPlistHandler.h"
#import "egnyteMobilePadAppDelegate.h"
#import "CustomTableCell.h"
#import "DbHelper.h"
#import "Utilities.h"
#import "JSON.h"
#import <QuartzCore/QuartzCore.h>

@protocol FolderBrowserViewDelegate <NSObject>
-(void)setSelectedDir:(NSString*)selectedDir selectedPID:(NSString*)selectedPID forAction:(NSString*)actionType;
@end

@interface FolderBrowserViewController : UIViewController {
	UINavigationController *rootViewNavigationController;
	NSFetchedResultsController *fetchedResultsController;
    NSManagedObjectContext *managedObjectContext;
	NSString *currentPID;
	NSString *currentAbsolutePath;
	IBOutlet UITableView *tableView;
	NSMutableData *responseData;
	NSSortDescriptor *folderFilePartitionSortDescriptor;
	NSSortDescriptor *defaultSortDescriptor;
	NSURLConnection *currentConnection;
	IBOutlet UIActivityIndicatorView  *loadingSpinner;
	NSManagedObject *currentObject;
	id <FolderBrowserViewDelegate> folderBrowser_delegate;
    IBOutlet UIBarButtonItem *selectDirBtnItem;
    IBOutlet UILabel *rootViewToastMsg;
	
    NSMutableArray *selectedRowArray;
    NSManagedObject *selectedObj;
    NSString *actionType;
}
@property (nonatomic, retain) NSManagedObject *selectedObj;
@property (nonatomic, retain) NSMutableArray *selectedRowArray;
@property(nonatomic,assign) id <FolderBrowserViewDelegate> folderBrowser_delegate;
@property (nonatomic, retain) NSManagedObject *currentObject;
@property (nonatomic, assign) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSString *currentPID;
@property (nonatomic, retain) NSString *currentAbsolutePath;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSSortDescriptor *defaultSortDescriptor;
@property (nonatomic, retain) NSSortDescriptor *folderFilePartitionSortDescriptor;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) UINavigationController *rootViewNavigationController;
@property (nonatomic, retain) NSURLConnection *currentConnection;
@property (nonatomic, retain) NSString *actionType;
- (void) setDirectoryButtons: (NSString *)currentPath;
- (IBAction) selectedDir:(id)sender;
- (IBAction) cancel:(id)sender;
- (BOOL)loadDirectory:(NSString *)PID;
- (CustomTableCell *) configFileRowFormat:(NSString *)cellIdentifier;
- (CustomTableCell *) configFolderRowFormat:(NSString *)cellIdentifier;
- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath managedObj:(NSManagedObject *)managedObject;
- (void) getDirectoryFromServer:(NSString *)path;
-(void) reloadData;
-(void)browseToNextDepth;
- (void)initRoot:(id)sender;
-(void)initContextAndFetchController;
-(void) refreshDir;
- (BOOL) processFreshDirectoryJSON:(NSDictionary *)parsedJSON PID:(NSString*)folderPID currAbsPath:(NSString*)currAbsPath mObjContext:(NSManagedObjectContext*)mObjContext;
- (void)processObject:(NSArray *)item pid:(NSString *)PID currAbsPath:(NSString*)currAbsPath isFolder:(int)isFolder alreadyInLocalDb:(BOOL)alreadyInLocalDb localDbItem:(NSManagedObject *)localItem;
@end
