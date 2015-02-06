//
//  FolderBrowserViewController.m
//  egnyteMobileIOSUniversal
//
//  Created by Ritika on 26/09/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import "FolderBrowserViewController.h"


@implementation FolderBrowserViewController
@synthesize fetchedResultsController,rootViewNavigationController,folderFilePartitionSortDescriptor,defaultSortDescriptor,managedObjectContext,currentObject;
@synthesize tableView, currentPID, currentAbsolutePath;
@synthesize currentConnection,folderBrowser_delegate;
@synthesize selectedRowArray,selectedObj,actionType;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	if(![self loadDirectory:self.currentPID]){//loads the path
		if(![self loadDirectory:@"0"]){//if root dir doesn't exist, create it
			[self initRoot:self];
			[self loadDirectory:@"0"];
		}
	}
    loadingSpinner.layer.shadowColor = [UIColor grayColor].CGColor;
    loadingSpinner.layer.shadowRadius = 1;
    loadingSpinner.layer.shadowOpacity = 0.3;
    loadingSpinner.layer.shadowOffset = CGSizeMake(0, 1);
	responseData = [[NSMutableData data] retain];
	NSString *fullDomain = [DomainPlistHandler getDomainFromPlist];
	if (self.navigationItem.title == nil || [self.navigationItem.title isEqualToString:@""]
        || [self.navigationItem.title isEqualToString:@"Home"]) {
		//set domain name as navigation bar title on Root Level
		self.title = fullDomain;
	}
    
}
- (void)viewDidAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
	NSString *fullDomain = [DomainPlistHandler getDomainFromPlist];
	if (self.navigationItem.title == nil || [self.navigationItem.title isEqualToString:@""] || [self.navigationItem.title isEqualToString:@"Home"]) {
		
		self.title = fullDomain;
	}
    
    
	[self initContextAndFetchController];
    
	
	//reinit currentAbsolutePath & currentPID based on the first displayed item, because uinavigation back button messes it up
	if(![self.currentAbsolutePath isEqualToString:@""]
	   && [[self.fetchedResultsController sections] count]>0) {
        
        if (fetchedResultsController == nil)
            [self fetchedResultsController];
        self.tableView.allowsSelection = YES; //to be done while opening file
		self.tableView.alpha = 1.0;
		NSManagedObject *tempObject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		NSString *firstRowPath = [[tempObject valueForKey:@"path"] description];
		NSArray *tempArray = [firstRowPath componentsSeparatedByString:@"/"];
		int rowNameLength = [[tempArray objectAtIndex:([tempArray count]-1)] length];
		self.currentAbsolutePath = [firstRowPath substringToIndex:([firstRowPath length]-rowNameLength-1)];
		self.currentPID = [tempObject valueForKey:@"pid"];
	}
    
    if(![self.title isEqualToString:fullDomain]||self.title == NULL) {
		[self refreshDir];
	}
    
	//reinit navigationcontroller get mess up after togglemaster view
	rootViewNavigationController = [(egnyteMobilePadAppDelegate *)[[UIApplication sharedApplication] delegate] navigationController];
    
    selectDirBtnItem.enabled=YES;
    [self setDirectoryButtons:self.currentAbsolutePath];
    
    [self refreshDir];
	[super viewDidAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    //cancel any HTTP request in progress,if any
	if([loadingSpinner isAnimating]){
        if (self.currentConnection != nil) {
            [self.currentConnection cancel];
            [self.currentConnection release];
            self.currentConnection = nil;
        }
	}
	[super viewWillDisappear:YES];
}
-(void) setDirectoryButtons: (NSString *)currentPath {
    //disable select of folder on Root level
    NSString *fullDomain = [DomainPlistHandler getDomainFromPlist];
    
    if ([self.title isEqualToString:fullDomain] || [self.title isEqualToString:@"Shared"] || [self.title isEqualToString:@"Private"] ) {
        selectDirBtnItem.enabled = NO;
    }
}

-(void) refreshDir {
    //fetch row from core DB based on PID
	[self loadDirectory:self.currentPID];
	[self.tableView reloadData];
}
-(void)initContextAndFetchController{
    //init fetch Result controller & managedObj context
    if (self.managedObjectContext == nil) {
        self.managedObjectContext = [(egnyteMobilePadAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        self.fetchedResultsController = nil;
        [self fetchedResultsController];
    } else if (self.fetchedResultsController == nil) {
        [self fetchedResultsController];
    }
}
- (void)initRoot:(id)sender {
    //initRoot for Shared and Private folder
    [self initContextAndFetchController];
    NSIndexPath *currentSelection = [self.tableView indexPathForSelectedRow];
    if (currentSelection != nil) {
        [self.tableView deselectRowAtIndexPath:currentSelection animated:NO];
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
	[self.tableView reloadData];
}
-(id)initTableWithDelegate:(NSString *)cPID path:cPath{
	//Initialize view, PID & path
	self.currentPID = [cPID retain];
	self.currentAbsolutePath = [cPath retain];
	return [super initWithNibName:@"FolderBrowserViewController" bundle:nil];
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


-(IBAction)selectedDir:(id)sender {
    //set the selected destination directory path & PID
    if(self.selectedObj != nil) {
        
        NSArray *tempArray = [[[[self.selectedObj objectID] URIRepresentation] absoluteString] componentsSeparatedByString:@"/"];
        NSString *PID  = [tempArray objectAtIndex:[tempArray count] - 1];
        [folderBrowser_delegate setSelectedDir:[self.selectedObj valueForKey:@"path"] selectedPID:PID forAction:self.actionType];
        
    } else {
        [folderBrowser_delegate setSelectedDir:currentAbsolutePath selectedPID:self.currentPID forAction:self.actionType];
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)cancel:(id)sender {
    //cancel folder selection
    [self dismissModalViewControllerAnimated:YES];
    
}
#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    [self initContextAndFetchController];
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
	CustomTableCell *customCell;
	if ([[managedObject valueForKey:@"isFolder"] intValue] == 0)
        //custom file Row
		customCell = [self configFileRowFormat:@"file"];
	else
        //custom folder row
		customCell = [self configFolderRowFormat:@"folder"];
    
    [self configureCell:customCell atIndexPath:indexPath managedObj:managedObject];
	
    return customCell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self initContextAndFetchController];
    
    if([loadingSpinner isAnimating]) {
        if(self.currentConnection != nil) {
            [self.currentConnection cancel];
            [self.currentConnection release];
            self.currentConnection = nil;
        }
        //reinit currentAbsolutePath on new call because previous loading call messes it up
        NSArray *tempArray = [self.currentAbsolutePath componentsSeparatedByString:@"/"];
        int rowNameLength = [[tempArray objectAtIndex:([tempArray count]-1)] length];
        self.currentAbsolutePath = [self.currentAbsolutePath  substringToIndex:([self.currentAbsolutePath length]-rowNameLength-1)];
    }
    
    self.currentObject = nil;
    self.currentObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    
    // load child list
    self.tableView.alpha = .3f;
    int isFolder = [[self.currentObject valueForKey:@"isFolder"] intValue];
    if (isFolder != 0) {//0 is file; 1 or 2 is for folers
        NSManagedObjectID *moID = [self.currentObject objectID];
        NSArray *tempArray = [[[moID URIRepresentation] absoluteString] componentsSeparatedByString:@"/"];
        self.currentPID = [tempArray objectAtIndex:[tempArray count]-1];
        
        self.currentAbsolutePath = [NSString stringWithFormat:@"%@/%@",self.currentAbsolutePath,[[self.currentObject valueForKey:@"name"] description]];
        
        [loadingSpinner startAnimating];
        //query next level down for folder browsering
        [self getDirectoryFromServer:self.currentAbsolutePath];
    } else {
    }
    
}
//configure file row format
- (CustomTableCell *) configFileRowFormat:(NSString *)cellIdentifier {
	
	CGRect CellFrame = CGRectMake(0, 0, 300, 60);
	CustomTableCell *customCell = [[[CustomTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fileCell"] autorelease];
	customCell.contentView.alpha =.3f;
	customCell.selectionStyle = UITableViewCellSelectionStyleNone;
	customCell.userInteractionEnabled = NO;
	[customCell setFrame:CellFrame];
	
	return customCell;
}
//configure folder row format
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
    label.frame =  kiPhoneLabelRect;
	label.opaque = NO;
    
	UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kCellImageViewTag];
    
	if (!isFolder) {
		cell.accessoryView = nil;
		UILabel *nameLbl = (UILabel *)[cell viewWithTag:ROW_NAME_LABEL_TAG];
		UILabel *metadataLbl = (UILabel *)[cell viewWithTag:ROW_METADATA_LABEL_TAG];
        nameLbl.frame = CGRectMake(44, 0, 270, 25);
        metadataLbl.frame = CGRectMake(44, 22, 270, 20);
        
        long size = [[managedObject valueForKey:@"size"] longValue];
		if (size<1)
			size = 1;
		
        NSString *owner = [[managedObject valueForKey:@"owner"] description];
        NSString *displayedTimestamp = [[managedObject valueForKey:@"timeStamp"] description];
		nameLbl.text = rowName;
		nameLbl.lineBreakMode = UILineBreakModeMiddleTruncation;
        NSString *fileSize = [Utilities humanFriendlyFileSize:size];
		metadataLbl.text = [NSString stringWithFormat:@"%@ | %@ | %@", fileSize, displayedTimestamp, owner];
        imageView.image = [UIImage imageNamed:@"icon_img.png"];
        
	}else{//it's a folder
        
		UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:kCellLabelTag];
		nameLabel.text = [rowName retain];
        nameLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
		[rowName release];
        
		NSString *dirPath = [managedObject valueForKey:@"path"];
		if (!([dirPath isEqualToString:@"/Shared"] || [dirPath isEqualToString:@"/Private"])) {
            
		} else {
			cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
		}
        
        imageView.image = [UIImage imageNamed:@"icon_shared.png"];
        imageView.opaque = YES;
        
	}
    if (isFolder)
        imageView.frame=CGRectMake(5, 7, 33, 30);
    cell.imageView.image = NULL;
    
}
//get Directory HTTP Request
-(void) getDirectoryFromServer:(NSString *)path{
    
    NSURL *url = [Utilities getDirectoryURLForPath:path];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
														   cachePolicy: NSURLRequestReloadIgnoringCacheData
													   timeoutInterval: REQUEST_TIMEOUT];
    [Utilities setUniversalGETRequestHeaders:request];
	
    self.currentConnection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] retain];
	
}

#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	int statusCode = [((NSHTTPURLResponse *)response) statusCode];
	
	NSRange listCfsFolder = [[[response URL] absoluteString] rangeOfString:@"list_content"];
    
    if ((listCfsFolder.location != NSNotFound) && statusCode == 200) {//directory browse response
		
    } else {
        [connection cancel];
		[loadingSpinner stopAnimating];
        self.tableView.alpha = 1.0;
        rootViewToastMsg.text = [Utilities processStatusCodeForDirectoryView:statusCode];
		rootViewToastMsg.hidden = NO;
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
        }
		return;
	}
	
    [responseData setLength:0];
}
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse{
    return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [responseData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	// Once this method is invoked, "responseData" contains the complete result
	[connection release];
    NSDictionary *parsedJSON ;
    NSString *rawContent = [[NSString alloc]  initWithBytes:[responseData bytes]
													 length:[responseData length]
												   encoding: NSUTF8StringEncoding];
	SBJsonParser *json = [[SBJsonParser alloc] init];
	
	
	NSError *jsonError = nil;
	parsedJSON = [[json objectWithString:rawContent error:&jsonError] retain];
    [rawContent release];
	rawContent = nil;
    [json release];
    json = nil;
	int isFolder = (int)[[self.currentObject valueForKey:@"isFolder"] integerValue];
	if(isFolder){//if from folder, then directory browser needs to parse json
        if([self processFreshDirectoryJSON:parsedJSON PID:self.currentPID currAbsPath:self.currentAbsolutePath mObjContext:self.managedObjectContext])
            [self browseToNextDepth];
    }
    //hide spinner
    //maybe needs to occur before calling browseToNextDepth
    [loadingSpinner stopAnimating];
    [parsedJSON release];
    parsedJSON = nil;
    
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    connection = nil;
    [responseData release];
	[loadingSpinner stopAnimating];
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
	}
}
//use to show failure as toast message
-(void)hideRootViewToastMsg:(id)sender{
	rootViewToastMsg.hidden = YES;
}
//process get directory JSON response to save to local CoreData DB
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
					
					NSString *rowName = [[rows objectAtIndex:i] valueForKey:@"name"];
					int isFolder = [[[rows objectAtIndex:i] valueForKey:@"isFolder"] integerValue];
					
					if (isFolder) {
						if(![dirDictionary objectForKey:rowName]){
                            //delete found folder item that no longer exists in foler on server
							[DbHelper deleteItemByPath:[NSString stringWithFormat:@"%@/%@",currAbsPath,rowName] ObjContext:self.managedObjectContext];
						}
					} else {
                        //dont delete new file created & not uploaded having egnyteID =nil
						if(![filesDictionary objectForKey:rowName]){
							NSString *egnyteID=[[rows objectAtIndex:i] valueForKey:@"egnyteID"];
							if(egnyteID != nil) {
							} else {
								//delete found file item that no longer exists in foler on server
								NSString *deletePathOnServer = [NSString stringWithFormat:@"%@/%@",currAbsPath,rowName] ;
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
-(void) reloadData {
	
	[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
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

-(void)browseToNextDepth{
	
    //browse to next level after processing recieved JSON response from cloud
    FolderBrowserViewController *folderBrowserView = [[FolderBrowserViewController alloc] initTableWithDelegate:self.currentPID
                                                                                                           path:self.currentAbsolutePath];
    folderBrowserView.actionType = self.actionType;
    folderBrowserView.folderBrowser_delegate = folderBrowser_delegate;
	NSString *dirName = [[self.currentObject valueForKey:@"name"] description];
	[folderBrowserView setTitle:dirName];
	
	[self.navigationController pushViewController:folderBrowserView animated:YES];
	[folderBrowserView release];
    
    self.tableView.allowsSelection = YES;
	self.tableView.alpha = 1.0;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES;
}


@end
