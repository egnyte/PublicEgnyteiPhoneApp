//
//  MoveCopyHandler.h
//  egnyteMobilePhone
//
//  Created by Steven Xi Chen on 4/11/11.
//  Copyright 2011 Egnyte Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSON.h"
@implementation NSURLRequest (ServiceClient)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host{
	return YES;
}
@end

@interface MoveCopyHandler : NSObject  {
	NSMutableData *responseData;//NSURLConnection response
    NSURLConnection *currentConnection;
}

@property (nonatomic, assign) NSMutableData *responseData;

-(id)init;
-(int)moveCopyActionFromPath:(NSString*)currentPath toDestPath:(NSString*)descPath action:(NSString*)fileAction name:(NSString*)name isFolder:(int)isFolder;
@end
