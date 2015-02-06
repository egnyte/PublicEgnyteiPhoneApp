//
//  Utilities.h
//  egnyteMobilePhone
//
//  Created by Steve Chen on 7/28/10.
//  Copyright 2010 Egnyte Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "DomainPlistHandler.h"
#import <Security/Security.h>
#import "zlib.h"
#import <AVFoundation/AVAssetExportSession.h>
@interface Utilities : NSObject {
    
}

+ (void) setAuthHeader: (NSMutableURLRequest *)request;
+ (NSMutableURLRequest *) setUniversalPOSTRequestHeaders: (NSMutableURLRequest *)request;
+ (NSMutableURLRequest *) setUniversalGETRequestHeaders: (NSMutableURLRequest *)request;
+ (NSMutableURLRequest *) setUniversalDeleteRequestHeaders: (NSMutableURLRequest *)request;

+ (NSDictionary *) parseNSURLParameters: (NSURL *) url;
+ (NSString*) userAgent;

+ (NSString*) humanFriendlyFileSize: (long)bytes;
+ (NSString *)getMimeType:(NSString *)fileName;
+ (void) showAlertViewWithTitle: (NSString*)title withMessage:(NSString*)msg delegate:(id)delegate;
+ (NSString *) applicationDocumentsDirectory;
+ (void) createParentDirectoryForPath: (NSString*)path;

+ (NSURL*) getDirectoryURLForPath: (NSString*)encodedPath;
+ (NSURL*) getDeleteURLForPath: (NSString*)encodedPath;
+ (NSURL*) getFileByPathURL: (NSString*)absolutePath;
+ (NSURL*) getFileActionURL: (NSString*)absolutePath;
+ (NSURL*) putFileURL: (NSString*)absolutePath;

+ (NSURL*) getMobileOAuthURL: (NSString*)ssoDomain;

+ (BOOL)isDeviceiPhone5;
+ (BOOL)processStatusCode:(int)sCode;
+ (NSString*)processStatusCodeForDirectoryView:(int)sCode;
@end
