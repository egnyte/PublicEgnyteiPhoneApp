//
//  egnyteMobilePadAppDelegate.m
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 2/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "egnyteMobilePadAppDelegate.h"
#import "RootViewController.h"
#import "DetailViewController.h"
#import "DomainPlistHandler.h"
#import "DbHelper.h"

@implementation egnyteMobilePadAppDelegate
@synthesize window;
@synthesize rootViewController, detailViewController, navigationController;
#pragma mark -
#pragma mark Application lifecycle

- (void)awakeFromNib {
	rootViewController.currentPID = @"0";//initial value
	rootViewController.currentAbsolutePath = @"";
    // Pass the managed object context to the root view controller.
    rootViewController.managedObjectContext = self.managedObjectContext;
}

-(void) popToRoot:(id)sender{
    //used to pop directory listing navigation to Root View
	[rootViewController.navigationController popToRootViewControllerAnimated:YES];
    rootViewController.currentPID = @"0";//initial value
	rootViewController.currentAbsolutePath = @"";
    
}

#pragma mark UIApplicationDelegate application lifecycle methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //setting App version on Settings App
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"kVersion"];
    [defaults synchronize];
    
    
    float deviceVersion = [[[UIDevice currentDevice]systemVersion]floatValue];
    if (deviceVersion >= 6.0 ) {
        self.window.rootViewController = navigationController;
    }
    else
        [self.window addSubview:navigationController.view];
    
	[self.window makeKeyAndVisible];
    
    
	return YES;
}

/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
    NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            abort();
        }
    }
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil)
        return managedObjectContext_;
    
    //initWithEntity:inManagedObjectContext
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
        
        [managedObjectContext_ setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
    }
    
    return managedObjectContext_;
}



/**
 * Determine if application is running from a test inside an external command-line build by xcodebuild.
 */
- (BOOL) isExternalBuild
{
    NSString *wrapper = [[[NSProcessInfo processInfo]environment] valueForKey:@"WRAPPER_NAME"];
    return wrapper != nil && ([wrapper rangeOfString:@"octest"].location != NSNotFound);
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil)
        return managedObjectModel_;
    
    if([self isExternalBuild]) {
        NSArray *bundles = [NSArray arrayWithObject:[NSBundle bundleForClass:[self class]]];
        managedObjectModel_ = [NSManagedObjectModel mergedModelFromBundles:bundles];
        
    } else {
        
        NSString *modelString = [[NSBundle mainBundle] pathForResource:@"egnyteCoreDataModel" ofType:@"momd"];
        NSURL *modelURL = [NSURL fileURLWithPath:modelString];
        managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
    }
    
    return managedObjectModel_;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    NSString *domain = [DomainPlistHandler getDomainFromPlist];
    
    NSString *storeString = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_egnyteMobile.sqlite",domain]];
    
    
    if ([self isExternalBuild]) {
        storeString = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"egnyteMobile.sqlite"];
    }
    
    
    NSURL *storeURL = [NSURL fileURLWithPath:storeString];
    
	// If the expected store doesn't exist, copy the default store.
	NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        abort();
    }
    return persistentStoreCoordinator_;
}

#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    
    if([self isExternalBuild]) {
        NSString *dir = [NSString stringWithFormat:@"%@/build", [[NSFileManager defaultManager] currentDirectoryPath]];
        return dir;
    } else {
        
        NSString *documentsDirectory = [Utilities applicationDocumentsDirectory];
        return documentsDirectory;
    }
    
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
    
}
- (void)dealloc {
    
    
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
	[rootViewController release];
	[detailViewController release];
    
	[window release];
	[super dealloc];
}


@end

