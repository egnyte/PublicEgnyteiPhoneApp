//
//  DbHelper.h
//  egnyteMobilePad
//
//  Created by Steven Xi Chen on 3/17/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "Utilities.h"
@interface DbHelper : NSObject {
    
}

+ (NSMutableArray *)findRowsByPID:(NSString *)pid ObjContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSMutableArray *)findRowByPath:(NSString *)path ObjContext:(NSManagedObjectContext *)managedObjectContext;

+ (NSManagedObject*)updateRow:(NSString *)path Key:(NSArray *)keys Value:(NSArray *)values ObjContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSManagedObject*)insertRow:(NSString *)path Key:(NSArray *)keys Value:(NSArray *)values ObjContext:(NSManagedObjectContext *)managedObjectContext;

+ (NSArray*)findFilesInsideDirectory:(NSString*)parentPath ObjContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSArray *)caseInsensitiveFindRowByPath:(NSString *)path ObjContext:(NSManagedObjectContext *)managedObjectContext;

+ (BOOL)deleteItemByPID:(NSString *)PID ObjContext:(NSManagedObjectContext *)managedObjectContext;
+ (BOOL)deleteChildNodesByPath:(NSString *)path ObjContext:(NSManagedObjectContext *)managedObjectContext;
+ (BOOL)deleteItemByPath:(NSString *)path ObjContext:(NSManagedObjectContext *)managedObjectContext;

+(NSManagedObject*)addFileRowForEID:(NSString*)eid timestamp:(NSString*)timestamp rName:(NSString*)rName pid:(NSString*)pid path:(NSString*)path size:(long)size isFolder:(int)isFolder owner:(NSString*)owner ObjContext:(NSManagedObjectContext *)managedObjectContext;
@end
