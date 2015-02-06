//
//  RootViewController.m
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 2/16/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//
#import "egnyteMobilePadAppDelegate.h"
#import "RootViewController.h"
#import "Utilities.h"
#import "JSON.h"
#import "DbHelper.h"
#import "DomainPlistHandler.h"


@implementation RootViewController

@synthesize currentConnection;
@synthesize showingImagePicker, fetchedResultsController, managedObjectContext,currentObject,rootViewNavigationController;
@synthesize rootTableView, currentPID, currentAbsolutePath, folderName;
@synthesize selectedRowArray;
@synthesize inEditMode;
@synthesize selectedImage, unselectedImage;
@synthesize bottomNavBar;
@synthesize domainName,username,rootViewToastMsg;
@synthesize actionButton,uploadBtn,newNameToolbar;
@synthesize detailViewController;
@synthesize createNewOrActionOptionToolbar,folderCheckedCnt,fileCheckedCnt,folderNewNameTextField;

@synthesize createNewFolder;


#pragma mark
#pragma mark Initilization methods

- init {
    self = [super init];
    return self;
}
- (void) toLoginView{
    //present login view
    LoginViewController *loginView = [[LoginViewController alloc] init];
    loginView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:loginView animated: YES];
    
}
-(void) initDomainPlist{
    
	//if user has successfully logged into domain before, bypass login screen
    if(![[DomainPlistHandler getAccessTokenFromPlist] isEqualToString:@""]){
		return;
	}else{
		//kicked out into login screen
		[DomainPlistHandler resetDefaultDomain];
        [self toLoginView];
	}
}

-(IBAction) userLogout{
    //Sign Out user from domain
	[DomainPlistHandler resetDefaultDomain];
    [self performSelector:@selector(toLoginView) withObject:nil afterDelay:0.5];
}


- (void) initDetailViewController {
    if (self.detailViewController == nil) {
        DetailViewController *dvc = [[DetailViewController alloc] init];
        dvc.rootViewController = self;
        self.detailViewController = dvc;
        [dvc release];
    }
}
- (void) initImagePicker {
    //initial UIImagePickerController to be shown for file upload
    imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.allowsEditing = YES;
    
	NSArray *mediaTypesAllowed = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    
	[imagePicker setMediaTypes:mediaTypesAllowed];
	imagePicker.delegate = self;
}
-(void)initVars{
    self.inEditMode = NO;
	self.detailViewController.rootViewController = self;
}

//initial selected row Array
- (void)initializeSelectedRowArray{
    
    fileCheckedCnt = 0;
    folderCheckedCnt = 0;
    
    CGRect tableViewFrame = rootTableView.frame;
    if(!createNewOrActionOptionToolbar.hidden) {
        tableViewFrame.size = CGSizeMake(tableViewFrame.size.width, tableViewFrame.size.height + 44);
        [rootTableView setFrame:tableViewFrame];
    }
    if(!isChangingMediaToUpload){
        createNewOrActionOptionToolbar.hidden = YES;
    }
    isChangingMediaToUpload = NO;
    [self removeNewFolderBar];
    [self initContextAndFetchController];
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[[self.fetchedResultsController sections] count]];
	for (int i=0; i < [[self.fetchedResultsController sections] count]; i++)
		[array addObject:[NSNumber numberWithBool:NO]];
	self.selectedRowArray = array;
	[array release];
}

-(void)initContextAndFetchController {
    if (self.managedObjectContext == nil) {
        
        self.managedObjectContext = [(egnyteMobilePadAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        self.fetchedResultsController = nil;
        [self fetchedResultsController];
        
    } else if (self.fetchedResultsController == nil) {
        [self fetchedResultsController];
    }
}

-(void)setCurrentAbsolutePath:(NSString *)currentAP{
    [currentAP retain];
    [currentAbsolutePath release];
    currentAbsolutePath = currentAP;
}

-(id)initTableWithDelegate:(NSString *)cPID path:cPath{
	//Initialize view, PID & path
	self.currentPID = [cPID retain];
	self.currentAbsolutePath = [cPath retain];
	[self initializeSelectedRowArray];
	return [super initWithNibName:@"RootView" bundle:nil];
    
}

#pragma mark -
#pragma mark Add a new object

- (void)initRoot:(id)sender {
    //initRoot for Shared and Private folder
    [self initContextAndFetchController];
    NSIndexPath *currentSelection = [rootTableView indexPathForSelectedRow];
    if (currentSelection != nil) {
        [rootTableView deselectRowAtIndexPath:currentSelection animated:NO];
    }
    
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newSharedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    // If appropriate, configure the new managed object.
	[newSharedObject setValue:@"0" forKey:@"pid"];
	[newSharedObject setValue:[NSNumber numberWithInt:1] forKey:@"isFolder"];
	[newSharedObject setValue:@"Shared" forKey:@"name"];
	[newSharedObject setValue:@"/Shared" forKey:@"path"];
	[newSharedObject setValue:@"1" forKey:@"timeStamp"];
    
	
	NSManagedObject *newPrivateObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    // If appropriate, configure the new managed object.
	[newPrivateObject setValue:@"0" forKey:@"pid"];
	[newPrivateObject setValue:[NSNumber numberWithInt:2] forKey:@"isFolder"];
	[newPrivateObject setValue:@"Private" forKey:@"name"];
	[newPrivateObject setValue:@"/Private" forKey:@"path"];
	[newPrivateObject setValue:@"2" forKey:@"timeStamp"];
    
    
	
    // Save the context.
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [managedObjectContext persistentStoreCoordinator];
    NSError *error = nil;
    [persistentStoreCoordinator lock];
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserverForName:NSManagedObjectContextDidSaveNotification object:managedObjectContext queue:nil
                 usingBlock:^(NSNotification *notification) {
                     [managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                            withObject:notification waitUntilDone:YES];
                 }];
    if (![context save:&error]) {
        // Update to handle any error appropriately.
    }
    [dnc removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
	[persistentStoreCoordinator unlock];
    
    [self.fetchedResultsController indexPathForObject:newSharedObject];
	[self.fetchedResultsController indexPathForObject:newPrivateObject];
	[rootTableView reloadData];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    
    loadingSpinner.layer.shadowColor = [UIColor grayColor].CGColor;
    loadingSpinner.layer.shadowRadius = 1;
    loadingSpinner.layer.shadowOpacity = 0.3;
    loadingSpinner.layer.shadowOffset = CGSizeMake(0, 1);
	[self initVars];
    [NSFetchedResultsController deleteCacheWithName:nil];
	if(![self loadDirectory:self.currentPID]){//loads the path
		if(![self loadDirectory:@"0"]){//if root dir doesn't exist, create it
			[self initRoot:self];
			[self loadDirectory:@"0"];
		}
	}
    
	//edit mode disable
	self.inEditMode = NO;
	self.selectedImage = [UIImage imageNamed:@"selected.png"];
	self.unselectedImage = [UIImage imageNamed:@"unselected.png"];
    
	[self initializeSelectedRowArray];
	rootViewNavigationController = [(egnyteMobilePadAppDelegate *)[[UIApplication sharedApplication] delegate] navigationController];
    
    NSString *fullDomain = [DomainPlistHandler getDomainFromPlist];
	
    if (self.currentAbsolutePath != nil && [self.currentAbsolutePath isEqualToString:@""]) {
        //set domain name as navigation bar title on Root Level
		self.title = fullDomain;
        bottomNavBar.hidden=NO;
		[self initDomainPlist];
	}
    
	// 1) init  userinfo
	self.domainName = [DomainPlistHandler getDomainFromPlist];
    
    [self initImagePicker];
    [super viewDidLoad];
}


- (void)viewWillDisappear:(BOOL)animated {
	//remove new folder name toolbar if exist
    [self removeNewFolderBar];
	[super viewWillDisappear:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [self initContextAndFetchController];
    
	NSString *fullDomain = [DomainPlistHandler getDomainFromPlist];
	if (self.currentAbsolutePath != nil  && [self.currentAbsolutePath isEqualToString:@""]) {
		self.title = fullDomain;
        [self initDomainPlist]; //For Logout need inorder to show Login screen
		bottomNavBar.hidden=NO;
	}
    
	
	//reinit currentAbsolutePath & currentPID based on the first displayed item, because uinavigation back button messes it up
	if(![loadingSpinner isAnimating] && ![self.currentAbsolutePath isEqualToString:@""]
       && [[self.fetchedResultsController sections] count]>0) {
        
		NSManagedObject *tempObject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		NSString *firstRowPath = [[tempObject valueForKey:@"path"] description];
		NSArray *tempArray = [firstRowPath componentsSeparatedByString:@"/"];
		int rowNameLength = [[tempArray objectAtIndex:([tempArray count]-1)] length];
		self.currentAbsolutePath = [firstRowPath substringToIndex:([firstRowPath length]-rowNameLength-1)];
		self.currentPID = [tempObject valueForKey:@"pid"];
	}
    
    //reinit currentAbsPath &  currentPID which get messed up on refresh dir after localization
    NSArray *tempArrayPath = [self.currentAbsolutePath componentsSeparatedByString:@"/"];
    if([tempArrayPath count] > 1 && ![self.navigationItem.title isEqualToString: [tempArrayPath objectAtIndex:[tempArrayPath count] - 1]]){
        //messed view
        int rowNameLength = [[tempArrayPath objectAtIndex:([tempArrayPath count]-1)] length];
        
        self.currentAbsolutePath = [self.currentAbsolutePath  substringToIndex:([self.currentAbsolutePath length]-rowNameLength-1)];
        
        NSArray *foundArr = [DbHelper findRowByPath:self.currentAbsolutePath ObjContext:self.managedObjectContext];
        if([foundArr count] > 0){
            NSManagedObject *parentMObj = [foundArr objectAtIndex:0];
            
            NSManagedObjectID *moID = [parentMObj objectID];
            NSArray *tempArray = [[[moID URIRepresentation] absoluteString] componentsSeparatedByString:@"/"];
            self.currentPID = [tempArray objectAtIndex:[tempArray count]-1];
        }
        if([self.currentAbsolutePath isEqualToString:@""])
            self.currentPID = @"0";
        
    }
    
    if([self.currentAbsolutePath isEqualToString:@""]) {
        bottomNavBar.hidden = NO;
        
    }
    //refresh directory listing to show fetch folder listing from server stored in CoreData DB
    [self refreshDir];
    
	rootViewNavigationController = [(egnyteMobilePadAppDelegate *)[[UIApplication sharedApplication] delegate] navigationController];
    
    [self enableBottomToolBarActions];
    
    self.detailViewController.rootViewController = self;
    
    rootTableView.alpha = 1.0;
    [rootTableView setBounces:YES];
	[super viewDidAppear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return YES;
}

#pragma mark

//enable Bottom Toolbar buttons
- (void)enableBottomToolBarActions{
    
	
	actionButton.enabled = YES;
    newFolderBtn.enabled = NO;
    uploadBtn.enabled = NO;
    
    //no file/folder option for root & 1st level
    if ([currentAbsolutePath isEqualToString:@""]) {
		actionButton.enabled = NO;
        
	} else if ([currentAbsolutePath isEqualToString:@"/Shared"] || [currentAbsolutePath isEqualToString:@"/Private"]) {
        if (![[self.fetchedResultsController sections] count])
			actionButton.enabled = NO;
        
	} else {
        if (![[self.fetchedResultsController sections] count])
			actionButton.enabled = NO; //disable action button when no item on List
        
        newFolderBtn.enabled = YES;
		uploadBtn.enabled = YES;
	}
    
}


-(void) refreshDir{
    //refresh fetch entried for PID & reload tableview
	[self loadDirectory:self.currentPID];
	[self initializeSelectedRowArray];
    
    //hide action button when no item on list
    if ([[self.fetchedResultsController sections] count])
        actionButton.enabled = YES;
    else
        actionButton.enabled = NO;
    
    UINavigationController *navC = [(egnyteMobilePadAppDelegate *)[[UIApplication sharedApplication] delegate] navigationController];
    if([navC.topViewController isKindOfClass:[RootViewController class]] ){
        RootViewController *rootVCntrl = (RootViewController*)(navC.topViewController);
        [rootVCntrl.rootTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    } else {
        [rootTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
}

#pragma mark
#pragma mark UITextField delegate method
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    //validation for new folder name
    
    if ([folderNewNameTextField.text length] > 1 || ![string isEqualToString:@""]) {
        saveFolderButton.enabled = YES;
    } else {
        saveFolderButton.enabled = NO;
    }
    
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

#pragma mark -
//use to show failure as toast message
-(void)hideRootViewToastMsg:(id)sender{
	rootViewToastMsg.hidden = YES;
}

-(void)browseToNextDepth{
    //browse to next level after processing recieved JSON response from cloud
    
    RootViewController *rootSubView = [[RootViewController alloc] initTableWithDelegate:self.currentPID
                                                                                   path:self.currentAbsolutePath];
	rootSubView.detailViewController = self.detailViewController;
	NSString *dirName = [[self.currentObject valueForKey:@"name"] description];
	[rootSubView setTitle:dirName];
    
    detailViewController.rootViewController = rootSubView;
    
	[rootViewNavigationController pushViewController:rootSubView animated:YES];
	[rootSubView release];
    
}

-(void) reloadData {
    if ([[self.fetchedResultsController sections] count])
        actionButton.enabled = YES;
    else
        actionButton.enabled = NO;
    
    [rootTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (BOOL)loadDirectory:(NSString *)PID {
    //load directory based on Parent Id
	if (self.managedObjectContext == nil)
        self.managedObjectContext = [(egnyteMobilePadAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    
	NSFetchRequest *fetchRequest = [NSFetchRequest alloc];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
    
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pid == %@",PID];
	[fetchRequest setPredicate:predicate];
    
    
	NSArray *sortDescriptors;
	
	if ([PID isEqualToString:@"0"]) {//pseudo sort root directory
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:YES];
        sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        
	} else {
        NSSortDescriptor *folderFileSeparateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"isFolder" ascending:NO];
        
        NSSortDescriptor *fileAscSeparateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        
        sortDescriptors = [NSArray arrayWithObjects:folderFileSeparateDescriptor,fileAscSeparateDescriptor,nil];
	}
    
	[fetchRequest setSortDescriptors:sortDescriptors];
    
    
    
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:self.managedObjectContext
                                                                                                 sectionNameKeyPath:@"name" cacheName:nil];
    
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    NSError *error = nil;
	if(![self.fetchedResultsController performFetch:&error]) { //returns BOOL for success
		return NO;
	}
    
	if (self.fetchedResultsController.fetchedObjects.count != 0)
        return YES;
    else if([PID isEqualToString:@"0"])
        return NO;
    else
        return YES;
}


-(IBAction) useMediaPicker:(id) sender{
    
    //show image picker for upload
	[self removeNewFolderBar];
	[self presentModalViewController:imagePicker animated:NO];
	showingImagePicker = YES;
}

- (IBAction) newFolderAction {
    //show new folder name toolbar
    saveFolderButton.enabled = NO;
	if (showingImagePicker) {
		showingImagePicker = NO;
	}
    
	newNameToolbar.hidden = NO;
	folderNewNameTextField.text = @"";
	folderNewNameTextField.placeholder = @"New folder name";
	[folderNewNameTextField becomeFirstResponder];
	createNewFolder =  YES;
	
}

- (IBAction)saveFolder:(id)sender{
    //create folder HTTP request & hide folder name toolbar
	[folderNewNameTextField resignFirstResponder];
    NSString *trimmedName = [folderNewNameTextField.text stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    folderNewNameTextField.text = trimmedName;
    if([trimmedName isEqualToString:@""]) {
        
        NSString *alertMsg;
        if(createNewFolder)
            alertMsg = @"Please enter name of folder to be created.";
        [Utilities showAlertViewWithTitle:@"" withMessage:alertMsg delegate:nil];
        return;
    }
	if (createNewFolder)
		[self createFolder:folderNewNameTextField.text];
	
	[self removeNewFolderBar];
	CGRect tableViewFrame = rootTableView.frame;
	tableViewFrame.size = CGSizeMake(tableViewFrame.size.width, tableViewFrame.size.height + 44);
	[rootTableView setFrame:tableViewFrame];
	createNewOrActionOptionToolbar.hidden = YES;
    
}
//dimiss keyboard on cancel create folder
- (IBAction)removeNewFolderBar{
    //hide folder name toolbar
	if(!newNameToolbar.hidden) {
		CGRect tableViewFrame = rootTableView.frame;
		tableViewFrame.size = CGSizeMake(tableViewFrame.size.width, tableViewFrame.size.height + 44);
		[rootTableView setFrame:tableViewFrame];
	}
    
	newNameToolbar.hidden = YES;
    if([folderNewNameTextField isFirstResponder])
        [folderNewNameTextField resignFirstResponder];
}
//create entry on Coredats DB for new folder
-(NSManagedObject*)createNewFolderInCoreDBWithName:(NSString*)mFolderName withPID:(NSString*)folderPID serverPath:(NSString*)absolutePath objContext:(NSManagedObjectContext*)mObjContext {
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    [keys insertObject:@"pid" atIndex:[keys count]];
    [values insertObject:folderPID  atIndex:[values count]];
    [keys insertObject:@"isFolder" atIndex:[keys count]];
    if([[[absolutePath componentsSeparatedByString:@"/"]objectAtIndex:1] isEqualToString:@"Private"]) {
        [values insertObject:[NSNumber numberWithInt:2]  atIndex:[values count]];
    } else {
        [values insertObject:[NSNumber numberWithInt:1]  atIndex:[values count]];
    }
    
    [keys insertObject:@"name" atIndex:[keys count]];
    [values insertObject:mFolderName  atIndex:[values count]];
    [keys insertObject:@"path" atIndex:[keys count]];
    [values insertObject:[NSString stringWithFormat:@"%@/%@",absolutePath,mFolderName]  atIndex:[values count]];
    NSManagedObject *createFolderMObj = [DbHelper insertRow:absolutePath Key:keys Value:values ObjContext:mObjContext];
    if(createFolderMObj) {
        return createFolderMObj;
        
    }
    return nil;
    
}

//create folder HTTP request
-(BOOL) createFolder:(NSString *)fName {
    
    //create new folder HTTP request
	fName = [fName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([[fName substringFromIndex:[fName length]-1]isEqualToString:@"."]) {
		//Folder name cannot end with dot(.).
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Folder name cannot end with dot(.)."
														delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]autorelease];
		[alert show];
		return NO;
	}
    
	//check for whether folder with same name already exist
	NSString *path = [NSString stringWithFormat:@"%@/%@",self.currentAbsolutePath,fName];
	NSString *absolutePath = [NSString stringWithFormat:@"%@/%@",self.currentAbsolutePath,fName];
	
    NSArray *existingItem = [DbHelper caseInsensitiveFindRowByPath:absolutePath ObjContext:self.managedObjectContext];
    
    
	if([existingItem count]!=0 && [[existingItem objectAtIndex:0] valueForKey:@"isFolder"] != 0) {
		//folder already exists at path
        [Utilities showAlertViewWithTitle:@"" withMessage:@"Folder already exists." delegate:nil];
		return NO;
        
	} else {
        //create folder on Cloud HTTP Request
		[loadingSpinner startAnimating];
        
		NSURL *url = [Utilities getFileActionURL:path];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
                                                               cachePolicy: NSURLRequestReloadIgnoringCacheData
														   timeoutInterval: REQUEST_TIMEOUT];
        [Utilities setUniversalPOSTRequestHeaders:request];
        
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSMutableDictionary *requestDictionary = [[NSMutableDictionary alloc] init];
        [requestDictionary setObject:@"add_folder" forKey:@"action"];
        NSString *theBodyString = [requestDictionary JSONRepresentation];
        
        NSData *theBodyData = [theBodyString dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:theBodyData];
		currentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
		creatingNewFolder = YES;
        return YES;
	}
}


#pragma mark -
#pragma mark File or folder action methods
-(IBAction)toggleFileOrFolderAction {
	self.inEditMode = !self.inEditMode;
    rootTableView.alpha = 1.0;
	CGRect tableViewFrame = rootTableView.frame;
    if(self.inEditMode && !createNewOrActionOptionToolbar.hidden) { //resized tbl size messed by New ->Action successively
        tableViewFrame.size = CGSizeMake(tableViewFrame.size.width, tableViewFrame.size.height + 44);
        [rootTableView setFrame:tableViewFrame];
    }
    
    createNewOrActionOptionToolbar.hidden = YES; // action bar hidden by default
    
	if (self.inEditMode == YES) {
        
        folderCheckedCnt = 0; fileCheckedCnt = 0;//reset checked flag states.
        
		if (showingImagePicker) {
			showingImagePicker = NO;
		}
        
        if(!createNewOrActionOptionToolbar.hidden)
			tableViewFrame.size = CGSizeMake(tableViewFrame.size.width, tableViewFrame.size.height - 44);
        
	} else {
        //resize table view when no file/folder selected
        if(createNewOrActionOptionToolbar.hidden && (fileCheckedCnt != 0 || folderCheckedCnt != 0)){
            tableViewFrame.size = CGSizeMake(tableViewFrame.size.width, tableViewFrame.size.height + 44);
            [rootTableView setFrame:tableViewFrame];
        }
	}
    
    
    [self initializeSelectedRowArray];
	[self reloadData];
}

-(void)deleteBtnListener {
	[loadingSpinner startAnimating];
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Delete confirmation"
                                                     message:@"You are about to delete all versions of the selected files/folders."
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Delete", nil] autorelease];
    alert.tag = DELETE_ALERT;
    [alert show];
}

-(int)deleteSelectedFileOrFolderForPath:(NSString*)path egnyteId:(NSString*)egnyteId isFolder:(int)isFolder{
    
	if (isFolder == 0 && egnyteId == nil) {
		//local file only & not uploaded to server.so delete local file only
		return 200;
	} else {
		NSURL *theURL = [Utilities getDeleteURLForPath:path];
        
		NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL: theURL
                                                                  cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                              timeoutInterval: REQUEST_TIMEOUT];
        
        
        [Utilities setUniversalDeleteRequestHeaders:theRequest];
        
		NSError *error;
		NSURLResponse *response;
		NSHTTPURLResponse *httpResponse;
		NSData *dataReply;
		id stringReply;
		
		dataReply = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&error];
		if (dataReply == nil) {
			if (error != nil) {
				return 0;
			}
		}
		stringReply = (NSString *)[[NSString alloc] initWithData:dataReply encoding:NSUTF8StringEncoding];
		[loadingSpinner stopAnimating];
		httpResponse = (NSHTTPURLResponse *)response;
		int statusCode = [httpResponse statusCode];
        
        if (statusCode == 200) {
            return statusCode;
			if([stringReply isEqualToString:@"true"]){
                [stringReply release];
                return statusCode;
            }
            else {
                [stringReply release];
                return 401;
            }
		}
        [stringReply release];
		return statusCode;
	}
	return 0;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    //handle delete alert
    if((alertView.tag == DELETE_ALERT) && buttonIndex == alertView.cancelButtonIndex){
        //cancel delete
        [loadingSpinner stopAnimating];
		[self toggleFileOrFolderAction];//does initializeSelectedRowArray and reloadData inside
    } else if(alertView.tag == DELETE_ALERT){
        
        //actual file/folder delete
		BOOL errorDeletingSomeFiles = NO;
		for (int i=[self.selectedRowArray count]-1; i>=0; i--) {
			if([[self.selectedRowArray objectAtIndex:i] boolValue]==YES) {
				NSIndexPath *tempIndexPath = [NSIndexPath indexPathForRow:0 inSection:i];
                if([self deleteRowPermanently:tempIndexPath] == NO){
                    if (!errorDeletingSomeFiles)
                        errorDeletingSomeFiles = YES;//keep track of errors
                }
			}
		}
        
        [loadingSpinner stopAnimating];
		[self toggleFileOrFolderAction];//does initializeSelectedRowArray and reloadData inside
        
		if(errorDeletingSomeFiles == YES) {
            //failure in delete
            [Utilities showAlertViewWithTitle:@"Unauthorized" withMessage:@"You do not have permission to delete some files." delegate:nil];
        }
	}
}

- (BOOL) processFreshDirectoryJSON:(NSDictionary *)parsedJSON PID:(NSString*)folderPID currAbsPath:(NSString*)currAbsPath mObjContext:(NSManagedObjectContext*)mObjContext{
    @synchronized(parsedJSON) {
		
		if(parsedJSON !=NULL){
            
			//1)delete paths that no longer exists recursively for directories
			NSArray *files = [parsedJSON objectForKey:@"files"];
			NSArray *directories = [parsedJSON objectForKey:@"folders"];
			//dictionaries used to compare against localdb to see if local db needs to delete row or not
			NSMutableDictionary *dirDictionary = [[NSMutableDictionary alloc] initWithCapacity:[directories count]];
			NSMutableDictionary *filesDictionary = [[NSMutableDictionary alloc] initWithCapacity:[directories count]];
            
			for(int i=0;i<[directories count];i++) {
				[dirDictionary setObject:[NSNumber numberWithInt:1] forKey:[[directories objectAtIndex:i] valueForKey:@"name"]];
            }
			
			for(int i=0;i<[files count];i++) {
				[filesDictionary setObject:[NSNumber numberWithInt:1]  forKey:[[files objectAtIndex:i] valueForKey:@"name"]];
            }
            
            
            NSArray *rows = [[DbHelper findRowsByPID:folderPID ObjContext:self.managedObjectContext] retain];
            
            NSMutableDictionary *freshDictionary = [[NSMutableDictionary alloc] initWithCapacity:[rows count]];
			for(int i=0;i<[rows count];i++) {
				[freshDictionary setObject:[rows objectAtIndex:i] forKey: [(NSManagedObject *)[rows objectAtIndex:i] valueForKey:@"name"]];
            }
            
            
            
			if (self.managedObjectContext == nil)
				self.managedObjectContext = [(egnyteMobilePadAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
            
            
            
			if([rows count] > 0){//if local db hold rows, check to see if they still exist on the server
				for(int i=0;i < [rows count];i++){
					//dont delete new file/folder created & not uploaded egnyteID =nil
					
					NSString *rowName = [[rows objectAtIndex:i] valueForKey:@"name"];
					int isFolder = [[[rows objectAtIndex:i] valueForKey:@"isFolder"] integerValue];
					
					if (isFolder) {
						if(![dirDictionary objectForKey:rowName]){
                            NSArray *foundArr = [DbHelper findFilesInsideDirectory:[NSString stringWithFormat:@"%@/%@",currAbsPath,rowName] ObjContext:self.managedObjectContext];
                            if([foundArr containsObject:detailViewController.detailItem]) {
                                //when file is deleted then remove detailItem if shown
                                self.detailViewController.title = @"";
                                self.detailViewController.detailItem = nil;
                                self.detailViewController.documentWebview.hidden = YES;
                            }
							[DbHelper deleteItemByPath:[NSString stringWithFormat:@"%@/%@",currAbsPath,rowName] ObjContext:self.managedObjectContext];
						}
					} else {
						if(![filesDictionary objectForKey:rowName]){
							NSString *egnyteID=[[rows objectAtIndex:i] valueForKey:@"egnyteID"];
							if(egnyteID == nil) {
                                [self deleteFileFromFS:[[rows objectAtIndex:i] valueForKey:@"path"]];
							} else {
								NSString *deletePathOnServer = [NSString stringWithFormat:@"%@/%@",currAbsPath,rowName] ;
                                if([[self.detailViewController.detailItem valueForKey:@"path"] isEqualToString:deletePathOnServer]) {
                                    //when file is deleted then remove detailItem if shown
                                    self.detailViewController.title = @"";
                                    self.detailViewController.detailItem = nil;
                                    self.detailViewController.documentWebview.hidden = YES;
                                }
								[DbHelper deleteItemByPath:deletePathOnServer ObjContext:self.managedObjectContext];
								NSString *displayedDomain = [DomainPlistHandler getDomainFromPlist];
								NSString *physicalFilePath = [NSString stringWithFormat:@"%@/%@",displayedDomain,deletePathOnServer];
								NSString *deleteFileAtPath = [[Utilities applicationDocumentsDirectory] stringByAppendingPathComponent:physicalFilePath];
								
								if([[NSFileManager defaultManager] fileExistsAtPath:deleteFileAtPath ] == YES) //delete local file
									[[NSFileManager defaultManager] removeItemAtPath:deleteFileAtPath error:nil];
							}
						}
					}
				}
			}
			
			//update all paths for directories
            //try catch to handle exception if any in case of save to coredata DB
			@try {
                NSUInteger count = 0, LOOP_LIMIT = 500,count1 =0;
                NSManagedObject *localDbItem;
                for(NSArray *folder in directories) {
                    BOOL existsInDb = NO;
                    localDbItem = nil;
                    
                    if([freshDictionary count] !=0 && [freshDictionary objectForKey:[folder valueForKey:@"name"]]!=nil) {
                        existsInDb = YES;
                        localDbItem = [[freshDictionary objectForKey:[folder valueForKey:@"name"]]retain];
                    }
                    
                    
                    [self processObject:folder pid:folderPID currAbsPath:currAbsPath isFolder:YES alreadyInLocalDb:existsInDb localDbItem:localDbItem];
                    
                    count++;
                    if (count == LOOP_LIMIT) {
                        
                        // Bulk Save context for insert coredata object.
                        NSError *error = nil;
                        if (![self.managedObjectContext save:&error]) {
                        }
                        count = 0;
                    }
				}
                
				for(NSArray *file in files) {
                    BOOL existsInDb = NO;
                    localDbItem = nil;
                    
                    if([freshDictionary count] !=0 && [freshDictionary objectForKey:[file valueForKey:@"name"]]!=nil) {
                        existsInDb = YES;
                        localDbItem = [[freshDictionary objectForKey:[file valueForKey:@"name"]]retain];
                    }
                    
                    [self processObject:file pid:folderPID currAbsPath:currAbsPath isFolder:NO alreadyInLocalDb:existsInDb localDbItem:localDbItem];
                    
                    count1++;
                    if (count1 == LOOP_LIMIT) {
                        
                        // Bulk Save context for insert coredata object.
                        NSError *error = nil;
                        if (![self.managedObjectContext save:&error]) {
                        }
                        count1 = 0;
                    }
                }
                
                if (count != 0 || count1 != 0) {
                    // Save the context.
                    NSError *error = nil;
                    if (![self.managedObjectContext save:&error]) {
                    }
                }
                
			}  @catch (NSException* e) {
			}
            
            if([rows count] >0)
				[rows release]; //removed by build&anaylze
            [dirDictionary release];
			[filesDictionary release];
            [freshDictionary release];
            
			return YES;
		}
        
		return NO;
    }
    
}

//insert new or update row in coredata for folder listing JSON response entries
- (void)processObject:(NSDictionary *)item pid:(NSString *)PID currAbsPath:(NSString*)currAbsPath isFolder:(int)isFolder alreadyInLocalDb:(BOOL)alreadyInLocalDb localDbItem:(NSManagedObject *)localItem{
    [self initContextAndFetchController];
	NSString *path = [NSString stringWithFormat:@"%@/%@",currAbsPath,[item valueForKey:@"name"]];
    
	
	if(alreadyInLocalDb){//update action
        
        if(localItem==nil) {
            NSArray *existingItem = [DbHelper findRowByPath:path ObjContext:self.managedObjectContext];
            localItem = [existingItem objectAtIndex:0];
		}
        
		if(isFolder == 0){//update files
			NSString *newEID = [item valueForKey:@"entry_id"];
			NSString *owner = [item valueForKey:@"uploaded_by"];
            
            
			if(![[[localItem valueForKey:@"egnyteID"] description] isEqualToString:newEID] || ![[[localItem valueForKey:@"owner"] description] isEqualToString:owner]){
				//check entryID difference; if different, then update row
				NSMutableArray *keys = [[NSMutableArray alloc] init];
                NSMutableArray *values = [[NSMutableArray alloc] init];
				[keys insertObject:@"name" atIndex:[keys count]];
				[values insertObject:[item valueForKey:@"name"]  atIndex:[values count]];
				[keys insertObject:@"egnyteID" atIndex:[keys count]];
				[values insertObject:[item valueForKey:@"entry_id"]  atIndex:[values count]];
				[keys insertObject:@"timeStamp" atIndex:[keys count]];
				[values insertObject:[item valueForKey:@"last_modified"]  atIndex:[values count]];
				[keys insertObject:@"size" atIndex:[keys count]];
				[values insertObject:[item valueForKey:@"size"]  atIndex:[values count]];
				[keys insertObject:@"owner" atIndex:[keys count]];
				[values insertObject:[item valueForKey:@"uploaded_by"]  atIndex:[values count]];
				
				[DbHelper updateRow:path Key:keys Value:values ObjContext:self.managedObjectContext];
                [keys release];
                [values release];
			}
            
            
            
		}
        
        [localItem release];
	} else {//create new row into db
        
		// Create a new instance of the entity managed by the fetched results controller.
		NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
		NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:self.managedObjectContext];
        
        [newObject setValue:[item valueForKey:@"name"] forKey:@"name"];
        [newObject setValue:path forKey:@"path"];
        [newObject setValue:PID forKey:@"pid"];
        [newObject setValue:[NSNumber numberWithInt:isFolder] forKey:@"isFolder"];
        
		if (isFolder == 1 ||isFolder == 2) {
            
		} else {//file specific metadata
            
            [newObject setValue:PID forKey:@"pid"];
			[newObject setValue:[item valueForKey:@"name"] forKey:@"name"];
			[newObject setValue:[NSNumber numberWithInt:0] forKey:@"isFolder"];
			[newObject setValue:[item valueForKey:@"entry_id"] forKey:@"egnyteID"];
			[newObject setValue:[item valueForKey:@"last_modified"] forKey:@"timeStamp"];
			[newObject setValue:[item valueForKey:@"size"] forKey:@"size"];
			[newObject setValue:[item valueForKey:@"uploaded_by"] forKey:@"owner"];
		}
        
	}
    
}
-(void)showUploadingIndicator {
    UIApplication* app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = YES;
    rootTableView.alpha = .3f;
    rootTableView.userInteractionEnabled = NO;
    uploadingLbl.hidden = NO;
    itemLoadingDialogBox.hidden = NO;
    [loadingSpinner startAnimating];
}
-(void)hideUploadingIndicator {
    UIApplication* app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = NO;
    rootTableView.alpha = 1.0f;
    rootTableView.userInteractionEnabled = YES;
    uploadingLbl.hidden = YES;
    itemLoadingDialogBox.hidden = YES;
    [loadingSpinner stopAnimating];
}
#pragma mark
#pragma mark UIImagePickerController delegate
- (void) imagePickerController: (UIImagePickerController *)picker didFinishPickingMediaWithInfo: (NSDictionary *)info {
    //delegate to grap image/video picked from UIImagePickerController for upload
    [self showUploadingIndicator];
	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    NSData *uploadFileData = nil;
    NSString *uploadFileName = @"";
	if ([mediaType isEqualToString:@"public.image"]) {
        //picked image
		UIImage* picture = [info objectForKey:UIImagePickerControllerEditedImage];
        if (!picture)
            picture = [info objectForKey:UIImagePickerControllerOriginalImage];
        
		uploadFileData  = UIImagePNGRepresentation(picture);
		uploadFileName = @"myMobilePic.png";
		
	}  else if ([mediaType isEqualToString:@"public.movie"]) {
        //picked video
		NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
		uploadFileData = [[NSData dataWithContentsOfURL:videoURL] retain];
        uploadFileName = @"myMobileMovie.m4v";
	}
	//create upload HTTP Request for photo/video picked
    NSString *fileDestDir = [currentAbsolutePath stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
    UploadHandler *fileuploadManager = [[UploadHandler alloc] init];
    fileuploadManager.uploadDelegate = self;
    [fileuploadManager putFile:fileDestDir fileData:uploadFileData fileName:uploadFileName];
    [picker dismissModalViewControllerAnimated:YES];
    showingImagePicker = NO;
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self performSelector:@selector(dismissModalView) withObject:nil afterDelay:0.2];
	showingImagePicker = NO;
}
//dimiss image picker controller
- (void)dismissModalView {
	[self dismissModalViewControllerAnimated:YES];
}
#pragma mark
#pragma mark UploadHandler delegate methods

//handling for file upload failed
- (void)fileUploaderNOTSuccessfulAlertListener {
    [self hideUploadingIndicator];
}
//insert row locally for successfull file upload
-(void)fileUploaderSuccessfulAlertListenerwithEgyteId:(NSString*)egyteId fileName:(NSString*)fName fileSize:(long)fileSize {
    [self hideUploadingIndicator];
 	NSManagedObjectContext *uploadObjcontext = [(egnyteMobilePadAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
 	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
 	[dateFormatter setDateFormat:@"EEEE, MMM dd, yyyy hh:mm:ss a"];
    
    NSString *currentTimestampString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter release];
    [DbHelper addFileRowForEID:egyteId timestamp:currentTimestampString rName:fName pid:self.currentPID path:[self.currentAbsolutePath stringByAppendingPathComponent:fName] size:fileSize isFolder:0 owner:username ObjContext:uploadObjcontext];
    [self refreshDir];
}

//view controller knows finished file upload
-(void)fileUploaderFinishedListener {
	UIApplication* app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = NO;
    rootTableView.alpha = 1.0f;
    rootTableView.userInteractionEnabled = YES;
    
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self initContextAndFetchController];
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self initContextAndFetchController];
    
	NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
	// Dequeue or create a cell of the appropriate type.
	CustomTableCell *cell;
    
    if ([[managedObject valueForKey:@"isFolder"] intValue] == 0)
        cell = [self configFileRowFormat:@"file"];
    else
        cell = [self configFolderRowFormat:@"folder"];
    // }
    
    [self configureCell:cell atIndexPath:indexPath managedObj:managedObject];
    
    return cell;
}

- (CustomTableCell *) configFileRowFormat:(NSString *)cellIdentifier {
	
	CustomTableCell *customCell = [[[CustomTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fileCell"] autorelease];
	return customCell;
}

- (CustomTableCell *) configFolderRowFormat:(NSString *)cellIdentifier {
	CustomTableCell *customCell = [[[CustomTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"folderCell"] autorelease];
	customCell.accessoryType = UITableViewCellAccessoryNone;
	
	return customCell;
}

//initialize row view
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath managedObj:(NSManagedObject *)managedObject{
	NSString *rowName = [[managedObject valueForKey:@"name"] description];
	UILabel *label = (UILabel *)[cell.contentView viewWithTag:kCellLabelTag];
    int isFolder = [[managedObject valueForKey:@"isFolder"] intValue];
    
    label.frame = (self.inEditMode) ? kiPhoneLabelIndentedRect : kiPhoneLabelRect;
	label.opaque = YES;
    
	
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kCellImageViewTag];
	NSNumber *selectedForDelete = [self.selectedRowArray objectAtIndex:indexPath.section];
	cell.imageView.image = imageView.image = ([selectedForDelete boolValue]) ? self.selectedImage : self.unselectedImage;
	cell.contentView.alpha = 1.0;
	
    
	if (!isFolder) {
		cell.accessoryView = nil;
		UILabel *nameLbl = (UILabel *)[cell viewWithTag:ROW_NAME_LABEL_TAG];
		UILabel *metadataLbl = (UILabel *)[cell viewWithTag:ROW_METADATA_LABEL_TAG];
		if(self.inEditMode) {
            nameLbl.frame = CGRectMake(74, 0, 240, 25);// in Edit mode
            metadataLbl.frame = CGRectMake(74, 22, 240, 20);
            
		} else {
            nameLbl.frame = CGRectMake(44, 0, 270, 25);//not in Edit mode
            metadataLbl.frame = CGRectMake(44, 22, 270, 20);
            
		}
		
        long size = [[managedObject valueForKey:@"size"] longValue];
		
		if (size<1)
			size = 1;  //set size as 1KB
        
        NSString *owner = [[managedObject valueForKey:@"owner"] description];
        NSString *displayedTimestamp = [[managedObject valueForKey:@"timeStamp"] description];
		nameLbl.text = rowName;
		nameLbl.lineBreakMode = UILineBreakModeMiddleTruncation;
        NSString *fileSize = [Utilities humanFriendlyFileSize:size];
		metadataLbl.text = [NSString stringWithFormat:@"%@ | %@ | %@", fileSize, displayedTimestamp, owner];
        imageView.image = [UIImage imageNamed:@"icon_img.png"];
	} else {//it's a folder
        
		UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:kCellLabelTag];
		nameLabel.text = rowName;
        nameLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
        
        imageView.image = [UIImage imageNamed:@"icon_shared.png"];
        imageView.opaque = YES;
        
	}
	
	if (self.inEditMode) {
        
		if (isFolder)
			imageView.frame=CGRectMake(40, 7, 33, 30);
        else
            imageView.frame=CGRectMake(40, 1, 30, 40);
        
	} else {
        
		if (isFolder)
			imageView.frame=CGRectMake(5, 7, 33, 30);
		else
            imageView.frame=CGRectMake(5, 1, 30, 40);
		cell.imageView.image = NULL;
        
	}
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    [rootTableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if([loadingSpinner isAnimating]) {
        //cancel previous call fo folder listing if in process
        if(currentConnection != nil) {
            [currentConnection cancel];
            [currentConnection release];
            currentConnection = nil;
        }
		if(!self.inEditMode)
			[loadingSpinner stopAnimating];
        //reinit currentAbsolutePath on new call because previous loading call messes it up
        NSArray *tempArray = [self.currentAbsolutePath componentsSeparatedByString:@"/"];
        int rowNameLength = [[tempArray objectAtIndex:([tempArray count]-1)] length];
        self.currentAbsolutePath = [self.currentAbsolutePath  substringToIndex:([self.currentAbsolutePath length]-rowNameLength-1)];
    }
    
    
	self.currentObject = nil;
    self.currentObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    
    if (!self.inEditMode) { // load child list
        rootTableView.alpha = .3f;
        int isFolder = [[self.currentObject valueForKey:@"isFolder"] intValue];
        
        if (isFolder != 0) {//0 is file; 1 is shared; 2 is private
            NSManagedObjectID *moID = [self.currentObject objectID];
            NSArray *tempArray = [[[moID URIRepresentation] absoluteString] componentsSeparatedByString:@"/"];
            self.currentPID = [tempArray objectAtIndex:[tempArray count]-1];
            
            self.currentAbsolutePath = [NSString stringWithFormat:@"%@/%@",self.currentAbsolutePath,[[self.currentObject valueForKey:@"name"] description]];
            //query next level down for folder browsering
            [loadingSpinner startAnimating];
            [self getDirectoryFromServer:self.currentAbsolutePath];
        } else {
            //regular file open
            
            [self initDetailViewController]; //instantiate viewcontroller for iphone
            
            self.detailViewController.title = [self.currentObject valueForKey:@"name"];
            [rootViewNavigationController pushViewController:self.detailViewController animated:YES];
            self.detailViewController.detailItem = self.currentObject;
        }
        
    } else { //	in edit mode
        
        if (self.selectedRowArray==nil || [self.selectedRowArray count] < [indexPath section])
            [self initializeSelectedRowArray];
        
        BOOL selected = [[self.selectedRowArray objectAtIndex:[indexPath section]] boolValue];
        [self.selectedRowArray replaceObjectAtIndex:[indexPath section] withObject:[NSNumber numberWithBool:!selected]];
        [rootTableView deselectRowAtIndexPath:indexPath animated:YES];
        
        
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        if ([[managedObject valueForKey:@"isFolder"] intValue] == 0){
            if(!selected){
                fileCheckedCnt++;
            }
            else {
                fileCheckedCnt--;
            }
        } else {
            if(!selected){
                folderCheckedCnt++;
            }
            else{
                folderCheckedCnt--;
            }
        }
        
        [rootTableView reloadData];
        
        [self conditionallyShowingActionButtons:self.currentAbsolutePath objectCnt:self.managedObjectContext];
    }
}


#pragma mark
#pragma mark FolderBrowserViewDelegate
-(void)setSelectedDir:(NSString*)selectedDir selectedPID:(NSString*)selectedPID forAction:(NSString*)actionType {
    //select folder for move/copy destination directory
    [loadingSpinner startAnimating];
    rootTableView.alpha = 0.3;
    [rootTableView setUserInteractionEnabled:NO];
    
    [self performSelectorInBackground:@selector(moveCopyInBackground:) withObject:[NSArray arrayWithObjects:selectedDir,actionType, nil]];
}
#pragma mark
#pragma mark Move/Copy methods
-(void)moveCopyInBackground:(NSArray*)details {
    //move Or copy the file/folder
    NSString *selectedDir = [details objectAtIndex:0];
    NSString *actionType = [details objectAtIndex:1];
    BOOL failureInMoveCopyAction = NO;
    NSMutableArray *moveOrCopySelectedRow = [selectedRowArray retain];
    for(int i = 0;i<[moveOrCopySelectedRow count];i++) {
        NSString *sourcePath = @"";
        if([[moveOrCopySelectedRow objectAtIndex:i] boolValue] == YES) {
            NSIndexPath *tempIndexPath = [NSIndexPath indexPathForRow:0 inSection:i];
            NSManagedObject *tempObj = [self.fetchedResultsController objectAtIndexPath:tempIndexPath];
            sourcePath = [tempObj valueForKey:@"path"];
            int isFolder = [[tempObj valueForKey:@"isFolder"]intValue];
            NSString *name = [tempObj valueForKey:@"name"];
            MoveCopyHandler *httpHandler = [[MoveCopyHandler alloc]init];
            int statusCode = [httpHandler moveCopyActionFromPath:sourcePath toDestPath:selectedDir action:actionType name:name isFolder:isFolder];
            [httpHandler release];
            if(statusCode == 200 && [actionType isEqualToString:MOVE_ACTION]) {
                [DbHelper deleteItemByPath:sourcePath ObjContext:self.managedObjectContext];
            } else if(statusCode == 200 && [actionType isEqualToString:COPY_ACTION]) {
            } else {
                failureInMoveCopyAction = YES;
                [Utilities processStatusCode:statusCode];
            }
            
        }
    }
    [self performSelectorOnMainThread:@selector(refreshDir) withObject:nil waitUntilDone:NO];
    rootTableView.alpha = 1.0;
    [rootTableView setUserInteractionEnabled:YES];
    [loadingSpinner stopAnimating];
    [self performSelectorOnMainThread:@selector(initializeSelectedRowArray) withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(toggleFileOrFolderAction) withObject:nil waitUntilDone:NO]; //toggle actions checkbox close
    if([actionType isEqualToString:MOVE_ACTION]){
        if(failureInMoveCopyAction == NO)
            [Utilities showAlertViewWithTitle:@"Move File/Folder action successfully" withMessage:@"" delegate:nil];
        else
            [Utilities showAlertViewWithTitle:@"Failure in move action for some file/folders " withMessage:@"" delegate:nil];
    } else if([actionType isEqualToString:COPY_ACTION]){
        if(failureInMoveCopyAction == NO)
            [Utilities showAlertViewWithTitle:@"Copy File/Folder action successfully" withMessage:@"" delegate:nil];
        else
            [Utilities showAlertViewWithTitle:@"Failure in copy action for some file/folders " withMessage:@"" delegate:nil];
    }
}

-(void)showMoveCopyFolderBrowser:(id)sender {
    FolderBrowserViewController *folderBrowserView = [[FolderBrowserViewController alloc] init];
    folderBrowserView.folderBrowser_delegate = self;
    if([sender tag] == MOVE_BTN_TAG)
        folderBrowserView.actionType = MOVE_ACTION;
    else
        folderBrowserView.actionType = COPY_ACTION;
    folderBrowserView.currentPID = @"0";
    UINavigationController *folderNavCntrl = [[UINavigationController alloc]initWithRootViewController:folderBrowserView];
    
    folderNavCntrl.navigationBar.barStyle = UIBarStyleBlackOpaque;
    folderNavCntrl.title = @"Home";
    folderNavCntrl.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:folderNavCntrl animated:YES];
}

-(void)conditionallyShowingActionButtons:(NSString*)currAbsPath objectCnt:(NSManagedObjectContext*)mCntxt{
    CGRect tableViewFrame = rootTableView.frame;
    if(createNewOrActionOptionToolbar.hidden && (folderCheckedCnt>=1 || fileCheckedCnt>= 1)){
        tableViewFrame.size = CGSizeMake(tableViewFrame.size.width, tableViewFrame.size.height - 44);
        createNewOrActionOptionToolbar.hidden = NO;
    }
    
    if(fileCheckedCnt == 0 && folderCheckedCnt == 0) {
        if(!createNewOrActionOptionToolbar.hidden)
            tableViewFrame.size = CGSizeMake(tableViewFrame.size.width, tableViewFrame.size.height + 44);
        createNewOrActionOptionToolbar.hidden = YES;
        [createNewOrActionOptionToolbar setItems:nil];
    } else {
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                      target:nil
                                                                                      action:nil];
        UIBarButtonItem *moveButton = [[UIBarButtonItem alloc]initWithTitle:@"Move" style:UIBarButtonItemStyleBordered target:self action:@selector(showMoveCopyFolderBrowser:)];
        moveButton.width = 50;
        moveButton.tag = MOVE_BTN_TAG;
        
        UIBarButtonItem *copyButton = [[UIBarButtonItem alloc]initWithTitle:@"Copy" style:UIBarButtonItemStyleBordered target:self action:@selector(showMoveCopyFolderBrowser:)];
        copyButton.width = 50;
        copyButton.tag = COPY_BTN_TAG;
        
        NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:3];
        [buttons addObject:flexibleSpace];
        UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteBtnListener)];
        deleteButton.style = UIBarButtonItemStyleBordered;
        deleteButton.width = 50;
        [buttons addObject:deleteButton];
        [buttons addObject:moveButton];
        [buttons addObject:copyButton];
        [createNewOrActionOptionToolbar setItems:buttons];
        [buttons release];
        [flexibleSpace release];
    }
    [rootTableView setFrame:tableViewFrame];
    
}

#pragma mark -
#pragma mark Delete Row methods
-(BOOL)deleteRowPermanently:(NSIndexPath *)tempIndexPath{
    
    NSManagedObject *objectToDelete = [self.fetchedResultsController objectAtIndexPath:tempIndexPath];
    int deleteStatusCode = [self deleteSelectedFileOrFolderForPath:[objectToDelete valueForKey:@"path"]
                                                          egnyteId:[objectToDelete valueForKey:@"egnyteID"]
                                                          isFolder:[[objectToDelete valueForKey:@"isFolder"] intValue]];
    
    if( deleteStatusCode == 200 || deleteStatusCode == 404){
        //  file/folder succesfully deleted on server
        //delete from core data
        [self deleteRowFromCoreDB:objectToDelete atIndexPath:tempIndexPath];
    } else {
        return NO;
    }
    
    return YES;
}
//delete corresponding row in Coredata DB for actual file/folder delete
-(void)deleteRowFromCoreDB:(NSManagedObject*)objToDelete atIndexPath:(NSIndexPath*)mSelectedIndexPath {
    NSString *displayedDomain = [DomainPlistHandler getDomainFromPlist];
    NSString *physicalFilePath = [NSString stringWithFormat:@"%@/%@",displayedDomain,[objToDelete valueForKey:@"path"]];
    NSString *deletePath;
    deletePath = [[Utilities applicationDocumentsDirectory] stringByAppendingPathComponent:physicalFilePath];
    if([[NSFileManager defaultManager]fileExistsAtPath:deletePath ] == YES){
        [[NSFileManager defaultManager] removeItemAtPath:deletePath error:nil];
    }
    [rootTableView beginUpdates];
    [self cleanOffDetailViewBasedOnDeletedObj:objToDelete];
    [DbHelper deleteItemByPath:[objToDelete valueForKey:@"path"] ObjContext:self.managedObjectContext];
    [self loadDirectory:self.currentPID];
    [self.selectedRowArray removeObjectAtIndex:mSelectedIndexPath.section];
    [rootTableView deleteSections:[NSIndexSet indexSetWithIndex:mSelectedIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [rootTableView endUpdates];
}

-(void)cleanOffDetailViewBasedOnDeletedObj:(NSManagedObject*)deletedObj {
    NSArray *foundArr = [DbHelper findFilesInsideDirectory:[deletedObj valueForKey:@"path"] ObjContext:self.managedObjectContext];
    if([[self.detailViewController.detailItem valueForKey:@"path"] isEqualToString:[deletedObj valueForKey:@"path"]]||[foundArr containsObject:detailViewController.detailItem]) {
        //when file is deleted then remove detailItem if shown
        self.detailViewController.title = @"";
        self.detailViewController.detailItem = nil;
        self.detailViewController.documentWebview.hidden = YES;
    }
}

//delete file copy in application directory
- (void) deleteFileFromFS:(NSString *)physicalFilePath {
    
    NSString *deletePath = [[Utilities applicationDocumentsDirectory] stringByAppendingPathComponent:physicalFilePath];
	if([[NSFileManager defaultManager] fileExistsAtPath:deletePath] == YES)
        [[NSFileManager defaultManager] removeItemAtPath:deletePath error:nil];
}

/*
 Set up the fetched results controller.
 */
#pragma mark -
#pragma mark Fetched results controller delegate
- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController != nil)
        return fetchedResultsController;
    
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest alloc];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // default sort key apparently has to be there, but real sort taken cared of in LoadDirectory method
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
	
	
    self.fetchedResultsController = aFetchedResultsController ;
    
	
    [aFetchedResultsController release];
    [fetchRequest release];
    
    return self.fetchedResultsController;
}



- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [rootTableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [rootTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [rootTableView endUpdates];
            break;
		case NSFetchedResultsChangeUpdate:
			[rootTableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *table = rootTableView;
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [table insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            break;
            
        case NSFetchedResultsChangeUpdate:
			if(newIndexPath == nil)	{
				[table reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
				break;
			}
			[self configureCell:[rootTableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath managedObj:self.currentObject];
            break;
            
        case NSFetchedResultsChangeMove:
            [table deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [table insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [rootTableView endUpdates];
}

#pragma mark -
#pragma mark Directory Listing methods

//get Directory HTTP Request
-(void) getDirectoryFromServer:(NSString *)path {
    
    NSURL *url = [Utilities getDirectoryURLForPath:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
														   cachePolicy: NSURLRequestReloadIgnoringCacheData
													   timeoutInterval: REQUEST_TIMEOUT];
    [Utilities setUniversalGETRequestHeaders:request];
    currentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}
#pragma mark
#pragma mark NSURLConnection delegate



- (NSURLRequest *)connection:(NSURLConnection *)connection  willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	int statusCode = [((NSHTTPURLResponse *)response) statusCode];
    
    
	if (creatingNewFolder && (statusCode == 200 || statusCode == 204 || statusCode == 201)) {//create folder response
        //create entry for newly created folder in Core data DB
        [self createNewFolderInCoreDBWithName:folderNewNameTextField.text withPID:self.currentPID serverPath:self.currentAbsolutePath objContext:self.managedObjectContext];
        creatingNewFolder = NO;
        [loadingSpinner stopAnimating];
        [connection cancel];
        connection = nil;
        //folder created should be shown on UI
        [self refreshDir];
        return;
		
	} else if(creatingNewFolder && statusCode != 200){
        
        [loadingSpinner stopAnimating];
        [Utilities processStatusCode:statusCode];
        creatingNewFolder = NO;
        [loadingSpinner stopAnimating];
        
	} else if (statusCode != 200){ //error
        [connection cancel];
        rootTableView.alpha = 1.0;
        rootViewToastMsg.text = [Utilities processStatusCodeForDirectoryView:statusCode];
		rootViewToastMsg.hidden = NO;
        [loadingSpinner stopAnimating];
		[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(hideRootViewToastMsg:) userInfo:nil repeats:NO];
        //reinit currentAbsolutePath & currentPID based on the first displayed item, because folder listing failed
        if(![loadingSpinner isAnimating] && ![self.currentAbsolutePath isEqualToString:@""] && [[self.fetchedResultsController sections] count]>0) {
            
            if (fetchedResultsController==nil)
                [self fetchedResultsController];
            
            NSManagedObject *tempObject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            NSString *firstRowPath = [[tempObject valueForKey:@"path"] description];
            NSArray *tempArray = [firstRowPath componentsSeparatedByString:@"/"];
            int rowNameLength = [[tempArray objectAtIndex:([tempArray count]-1)] length];
            self.currentAbsolutePath = [firstRowPath substringToIndex:([firstRowPath length]-rowNameLength-1)];
            self.currentPID = [tempObject valueForKey:@"pid"];
            self.detailViewController.rootViewController = self;
        }
		return;
	}
	responseData = [[NSMutableData data] retain];
    [responseData setLength:0];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	if (creatingNewFolder) {
		creatingNewFolder = NO;
        [loadingSpinner stopAnimating];
        [connection cancel];
        connection = nil;
        [self refreshDir];
        
		return;
	}
    [responseData appendData:data];
    
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    // Once this method is invoked, "responseData" contains the complete result
    connection = nil;
    
    NSDictionary *parsedJSON ;
    NSString *rawContent = [[NSString alloc]  initWithBytes:[responseData bytes]
													 length:[responseData length]
												   encoding: NSUTF8StringEncoding];
	SBJsonParser *json = [[SBJsonParser alloc] init];
	
	
	NSError *jsonError = nil;
    //parsed JSON data of directory listing response
	parsedJSON = [json objectWithString:rawContent error:&jsonError];
    [rawContent release];
	rawContent = nil;
    [responseData release];
    [json release];
    json = nil;
    
    if(parsedJSON != nil) {
        if([[self.currentObject valueForKey:@"isFolder"] integerValue]){//if from folder, then directory browser needs to parse json
            if([self processFreshDirectoryJSON:parsedJSON PID:self.currentPID currAbsPath:self.currentAbsolutePath mObjContext:self.managedObjectContext] && self.inEditMode == NO)
                [self browseToNextDepth]; //browse to next depth of folder
        } else
            self.detailViewController.detailItem = self.currentObject;
    }
	if (!self.inEditMode)
		[loadingSpinner stopAnimating];
	
    parsedJSON = nil;
    [parsedJSON release];
    
	
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    connection = nil;
    [responseData release];
	[loadingSpinner stopAnimating];
    rootTableView.alpha = 1.0;
    [Utilities showAlertViewWithTitle:[NSString stringWithFormat:@"Connection timed out (%d) ",error.code] withMessage:@"Please try again later." delegate:nil];
    
    
    //reinit currentAbsolutePath & currentPID based on the first displayed item, because folder listing failed
	if(![loadingSpinner isAnimating] && ![self.currentAbsolutePath isEqualToString:@""] && [[self.fetchedResultsController sections] count]>0) {
        
        if (fetchedResultsController==nil)
            [self fetchedResultsController];
        
		NSManagedObject *tempObject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		NSString *firstRowPath = [[tempObject valueForKey:@"path"] description];
		NSArray *tempArray = [firstRowPath componentsSeparatedByString:@"/"];
		int rowNameLength = [[tempArray objectAtIndex:([tempArray count]-1)] length];
		self.currentAbsolutePath = [firstRowPath substringToIndex:([firstRowPath length]-rowNameLength-1)];
		self.currentPID = [tempObject valueForKey:@"pid"];
        self.detailViewController.rootViewController = self;
	}
}


#pragma mark -
#pragma mark Memory management

- (void)viewDidUnload {
    imagePicker = nil;
    self.domainName = nil;
    self.username = nil;
    self.selectedRowArray = nil;
    self.currentPID  = nil;
    self.currentAbsolutePath = nil;
    [super viewDidUnload];
    
}


- (void)dealloc {
    [fetchedResultsController release];
    [imagePicker release];
    [rootTableView setDelegate:nil];
    [rootTableView setDataSource:nil];
    [self.domainName release];
    [self.username release];
    [self.selectedRowArray release];
    [self.currentPID release];
    [self.currentAbsolutePath release];
    [super dealloc];
}

@end


