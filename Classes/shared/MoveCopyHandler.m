//
//  MoveCopyHandler.m
//  egnyteMobilePhone
//
//  Created by Steven Xi Chen on 4/11/11.
//  Copyright 2011 Egnyte Inc. All rights reserved.
//

#import "MoveCopyHandler.h"
#import "DomainPlistHandler.h"
#import "Utilities.h"
#import "Constants.h"
#import "egnyteMobilePadAppDelegate.h"
@implementation MoveCopyHandler
@synthesize responseData;

-(id)init{
	
	return self;
}

#pragma mark
#pragma mark NSURLConnection delegate methods

//move/copy HTTP request
-(int)moveCopyActionFromPath:(NSString*)currentPath toDestPath:(NSString*)descPath action:(NSString*)fileAction name:(NSString*)name isFolder:(int)isFolder {
    //create move/copy Http request
    NSURL *theURL = [Utilities getFileActionURL:currentPath];
    
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL: theURL
                                                              cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                          timeoutInterval: REQUEST_TIMEOUT];
    [Utilities setUniversalPOSTRequestHeaders:theRequest];
    [theRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableDictionary *requestDictionary = [[NSMutableDictionary alloc] init];
    [requestDictionary setObject:fileAction forKey:@"action"];
    [requestDictionary setObject:[NSString stringWithFormat:@"%@/%@",descPath,name] forKey:@"destination"];
    
    NSString *theBodyString = [requestDictionary JSONRepresentation];
	
    NSData *theBodyData = [theBodyString dataUsingEncoding:NSUTF8StringEncoding];
    [theRequest setHTTPBody:theBodyData];
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
    // Some debug code, etc.
    
    
    httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = [httpResponse statusCode];
    return statusCode;
}


@end
