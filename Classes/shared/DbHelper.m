//
//  DbHelper.m
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 3/17/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import "DbHelper.h"
#import "DomainPlistHandler.h"

@implementation DbHelper

//execute fetch request based on PID
+ (NSArray *)findRowsByPID:(NSString *)pid ObjContext:(NSManagedObjectContext *)managedObjectContext{
	NSFetchRequest *request = [[NSFetchRequest alloc] init] ;
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	
	NSPredicate *predicate =[NSPredicate predicateWithFormat:@"pid == %@", pid];
	[request setPredicate:predicate];
	
    NSSortDescriptor *nsd = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:nsd, nil];
    [nsd release];
    [request setSortDescriptors:sortDescriptors];
	// Execute the fetch -- create a mutable copy of the result.
	//NSError *error;
	NSError *error = nil;
	NSArray *resultArray = [managedObjectContext executeFetchRequest:request error:&error];
	if(resultArray == nil) {
	}
    
    [sortDescriptors release];
    [request release];
	return resultArray;
}
//execute fetch request based on Path
+ (NSArray *)findRowByPath:(NSString *)path ObjContext:(NSManagedObjectContext *)managedObjectContext{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate =[NSPredicate predicateWithFormat:@"path == %@", path];
	[request setPredicate:predicate];
	[request setFetchLimit:1];
    
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error;
	NSArray *resultArray = [managedObjectContext executeFetchRequest:request error:&error];
    [request release];
	return resultArray;
}
//execute case insensitive fetch request based on Path
+ (NSArray *)caseInsensitiveFindRowByPath:(NSString *)path ObjContext:(NSManagedObjectContext *)managedObjectContext{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY path LIKE[c] %@", path];
	[request setPredicate:predicate];
	
    NSSortDescriptor *nsd = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:nsd, nil];
    [nsd release];
    [request setSortDescriptors:sortDescriptors];
    
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error;
	NSArray *resultArray = [managedObjectContext executeFetchRequest:request error:&error];
    [sortDescriptors release];
    [request release];
	return resultArray;
}
//fetch request for delete child of NSManaged object based on path
+ (BOOL)deleteChildNodesByPath:(NSString *)path ObjContext:(NSManagedObjectContext *)managedObjectContext{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];// autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:managedObjectContext];
    
	[request setEntity:entity];
    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"path BEGINSWITH %@",
                              [path stringByAppendingString:@"/"] ];
	[request setPredicate:predicate];
	
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error = nil;
	NSArray *objectArray = [managedObjectContext executeFetchRequest:request error:&error];
    //deleteChildNodesByPath array
	for(NSManagedObject *childNode in objectArray){
        //1 delete all children nodes recursively
        [managedObjectContext deleteObject:childNode];
    }
    
    [request release];
	return YES;
}
//fetch request to delete NSManaged based on PID
+ (BOOL)deleteItemByPID:(NSString *)PID ObjContext:(NSManagedObjectContext *)managedObjectContext {
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];// autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:managedObjectContext];
    [request setFetchLimit:1];
	[request setEntity:entity];
	
	NSPredicate *predicate =[NSPredicate predicateWithFormat:@"pid == %@", PID];
	[request setPredicate:predicate];
	
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error = nil;
	NSArray *objectArray = [managedObjectContext executeFetchRequest:request error:&error];
    //deleteItemByPID
    for(NSManagedObject *childNode in objectArray){
        // delete actual node
        [managedObjectContext deleteObject:childNode];
    }
    [request release];
	return YES;
}
//fetch request to delete NSManaged object based on Path
+ (BOOL)deleteItemByPath:(NSString *)path ObjContext:(NSManagedObjectContext *)managedObjectContext{
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];// autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:managedObjectContext];
    [request setFetchLimit:1];
	[request setEntity:entity];
	
	NSPredicate *predicate =[NSPredicate predicateWithFormat:@"path == %@", path];
	[request setPredicate:predicate];
	
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error = nil;
	NSArray *objectArray = [managedObjectContext executeFetchRequest:request error:&error];
    
	if([objectArray count]>0){
        NSManagedObject *item = [objectArray objectAtIndex:0];
        //1 delete all children nodes recursively
        if ([[item valueForKey:@"isFolder"]intValue] != 0) {
            [self deleteChildNodesByPath:path ObjContext:managedObjectContext];
            
        }
        //2 delete actual node
        [managedObjectContext deleteObject:item];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserverForName:NSManagedObjectContextDidSaveNotification object:managedObjectContext queue:nil
                     usingBlock:^(NSNotification *notification) {
                         [managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                                withObject:notification waitUntilDone:YES];
                     }];
        if (![managedObjectContext save:&error]) {
            // Update to handle any error appropriately.
        }
        [dnc removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    }
    
    [request release];
    
	return YES;
}
//fetch request to update NSManaged Object based on PID
+ (NSManagedObject*)updateRow:(NSString *)path Key:(NSArray *)keys Value:(NSArray *)values ObjContext:(NSManagedObjectContext *)managedObjectContext{
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setReturnsObjectsAsFaults:NO];
    [request setFetchLimit:1];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate =[NSPredicate predicateWithFormat:@"path == %@", path];
	[request setPredicate:predicate];
	
	// Execute the fetch -- create a mutable copy of the result
    
	NSManagedObject *foundObj = [[managedObjectContext executeFetchRequest:request error:&error] objectAtIndex:0];
	
	if (foundObj != nil) {
		for(int i = 0;i < [keys count];i++){
			@try {
                if (![[values objectAtIndex:i] isEqual:[NSNull null]])
                    [foundObj setValue:[values objectAtIndex:i] forKey:[keys objectAtIndex:i]];
                
			} @catch(NSException* e) {
			}
		}
        
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserverForName:NSManagedObjectContextDidSaveNotification object:managedObjectContext queue:nil
                     usingBlock:^(NSNotification *notification) {
                         [managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                                withObject:notification waitUntilDone:YES];
                     }];
        
        if (![managedObjectContext save:&error]) {
            // Update to handle any error appropriately.
        }
        [dnc removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
        
	}
    NSManagedObject *updatedObj = [[managedObjectContext executeFetchRequest:request error:&error] objectAtIndex:0];
    [request release];
	
	return updatedObj;
}
//fetch request to insert new NSManaged Object based
+ (NSManagedObject*)insertRow:(NSString *)path Key:(NSArray *)keys Value:(NSArray *)values ObjContext:(NSManagedObjectContext *)managedObjectContext{
	NSError *error = nil;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:managedObjectContext];
    
    
	NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:managedObjectContext];
	
    for(int i=0;i<[keys count];i++){
        [newObject setValue:[values objectAtIndex:i] forKey:[keys objectAtIndex:i]];
    }
    
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserverForName:NSManagedObjectContextDidSaveNotification object:managedObjectContext queue:nil
                 usingBlock:^(NSNotification *notification) {
                     [managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                            withObject:notification waitUntilDone:YES];
                 }];
    if (![managedObjectContext save:&error]) {
        // Update to handle any error appropriately.
        return nil;
    }
    [dnc removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
	
	
	
	return newObject;
}

//fetch request to get files inside based on parent folder path
+(NSArray*)findFilesInsideDirectory:(NSString*)parentPath ObjContext:(NSManagedObjectContext *)managedObjectContext{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"EgnyteLocalDirectory" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	NSPredicate *predicate =[NSPredicate predicateWithFormat:@"path BEGINSWITH %@ AND isFolder == %@", parentPath,[NSNumber numberWithInt:0]];
    
	[request setPredicate:predicate];
	
    NSSortDescriptor *nsd = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:nsd, nil];
    [request setSortDescriptors:sortDescriptors];
    [sortDescriptors release];
    [nsd release];
    
	// Execute the fetch -- create a mutable copy of the result
    NSError *error = nil;
	NSArray *foundArray = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	[request release];
    
    return foundArray;
}
//fetch request to add file row NSManaged Object based
+(NSManagedObject*)addFileRowForEID:(NSString*)eid timestamp:(NSString*)timestamp rName:(NSString*)rName pid:(NSString*)pid path:(NSString*)path size:(long)size isFolder:(int)isFolder owner:(NSString*)owner ObjContext:(NSManagedObjectContext *)managedObjectContext{
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    [keys insertObject:@"pid" atIndex:[keys count]];
    [values insertObject:pid  atIndex:[values count]];
    [keys insertObject:@"name" atIndex:[keys count]];
    [values insertObject:[NSString stringWithFormat:@"%@",rName]  atIndex:[values count]];
    if(eid) {
        [keys insertObject:@"egnyteID" atIndex:[keys count]];
        [values insertObject:eid  atIndex:[values count]];
    }
    
    [keys insertObject:@"timeStamp" atIndex:[keys count]];
    [values insertObject:timestamp atIndex:[values count]];
    
    [keys insertObject:@"size" atIndex:[keys count]];
    [values insertObject:[NSNumber numberWithLong:size] atIndex:[values count]];
    [keys insertObject:@"path" atIndex:[keys count]];
    [values insertObject:path atIndex:[values count]];
    
    NSArray *existingItem =[DbHelper findRowByPath:path  ObjContext:managedObjectContext];
    if([existingItem count]==0)
        return [DbHelper insertRow:path Key:keys Value:values ObjContext:managedObjectContext];
    else
        return [DbHelper updateRow:path Key:keys Value:values ObjContext:managedObjectContext];
	
    [keys release];
    [values release];
    
}
@end
