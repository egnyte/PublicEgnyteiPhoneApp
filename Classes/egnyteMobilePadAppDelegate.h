//
//  egnyteMobilePadAppDelegate.h
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 2/16/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MoveCopyHandler.h"

@class TextEditViewController;

@class RootViewController;
@class DetailViewController;
@interface egnyteMobilePadAppDelegate : NSObject <UIApplicationDelegate> {
	
    IBOutlet UIWindow *window;
	
	IBOutlet UINavigationController *navigationController;
	IBOutlet RootViewController *rootViewController;
	IBOutlet DetailViewController *detailViewController;
    
@private
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
    
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;
@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(void) popToRoot:(id)sender;
-(NSString *)applicationDocumentsDirectory;
- (BOOL) isExternalBuild;
@end
