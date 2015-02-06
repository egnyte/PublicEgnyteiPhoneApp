//
//  Utilities.m
//  egnyteMobilePhone
//
//  Created by Steve Chen on 7/28/10.
//  Copyright 2010 Egnyte Inc. All rights reserved.
//
#import <MobileCoreServices/MobileCoreServices.h>
#import "Utilities.h"
#import "Constants.h"
#import "egnyteMobilePadAppDelegate.h"
#import "MoveCopyHandler.h"
#import "LoginViewController.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVMediaFormat.h>

@implementation Utilities

+ (void) setAuthHeader: (NSMutableURLRequest *)request {
    //set authentication header for HTTP Request
    NSString *acess_token = [DomainPlistHandler getAccessTokenFromPlist];
    NSString *authHeader = [NSString stringWithFormat:@"%@ %@",@"Bearer",acess_token];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
}

+ (NSMutableURLRequest *)setUniversalGETRequestHeaders: (NSMutableURLRequest *)request {
    [self setAuthHeader: request];
	//setting GET Request Headers
    [request setValue:@"" forHTTPHeaderField:@"Cookie"];
	[request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setValue:CONST_CLIENT_NAME forHTTPHeaderField:@"Egnyte-Client-Name"];
	[request setValue:[Utilities userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:@"GET"];
    return request;
}

+ (NSMutableURLRequest *)setUniversalPOSTRequestHeaders: (NSMutableURLRequest *)request {
    [self setAuthHeader: request];
    //setting POST Request Headers
	[request setValue:CONST_CLIENT_NAME forHTTPHeaderField:@"Egnyte-Client-Name"];
    [request setHTTPMethod:@"POST"];
    
    return request;
}
+ (NSMutableURLRequest *)setUniversalDeleteRequestHeaders: (NSMutableURLRequest *)request {
    [self setAuthHeader: request];
    //setting DELETE Request Headers
    [request setValue:@"" forHTTPHeaderField:@"Cookie"];
	[request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setValue:CONST_CLIENT_NAME forHTTPHeaderField:@"Egnyte-Client-Name"];
	[request setValue:[Utilities userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:@"DELETE"];
    return request;
}

+ (NSString *)getMimeType:(NSString *)fileName {
    
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[fileName pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!MIMEType) {
        return @"application/octet-stream";
    }
    return NSMakeCollectable([(NSString *)MIMEType autorelease]);
}


#pragma mark -

+ (NSDictionary *) parseNSURLParameters: (NSURL *) url {
    //used to get accessToken & token type after successfully OAuth Login
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:6];
	NSString *query = url.query;
    
    if(query == nil) {
        query = [[[url absoluteString]componentsSeparatedByString:@"#"]objectAtIndex:1];
    }

	if (query != nil) {
		NSArray *pairs = [query componentsSeparatedByString:@"&"];
		
		for (NSString *pair in pairs) {
			NSArray *elements = [pair componentsSeparatedByString:@"="];
			NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			NSString *val = [[elements objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+"
                                                                                  withString:@" "];
			
			val = [val stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			id currentValue = [dict objectForKey:key];
			if (currentValue == nil) {
				[dict setObject:val forKey:key];
			} else if ([currentValue isKindOfClass:[NSArray class]]) {
				[currentValue addObject:val];
				[dict setObject:currentValue forKey:key];
			} else {
				[dict setObject:[NSMutableArray arrayWithObjects:currentValue, val, nil] forKey:key];
			}
		}
        
	}
	
	return dict;
	
}

+ (NSString*) userAgent {
    //user Agent to be sent on HTTP Request headers
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];
    return [NSString stringWithFormat:@"PublicEgnyte/%@ (Mobile; iPhone; %@; %@)",appVersion,iOSVersion,[[NSLocale currentLocale] localeIdentifier]];
}

#pragma mark -

+(NSString*)humanFriendlyFileSize:(long)bytes {
    if(bytes < 1024)
        return [NSString stringWithFormat:@"%ldbytes", bytes];
    else if(bytes >=1024 && bytes <= 1048575)
        return [NSString stringWithFormat:@"%ldKB", bytes/1024];
    else if(bytes >=1048576 && bytes <= 10485759)
        return [NSString stringWithFormat:@"%.1fMB", bytes/(1024.0*1024.0)];
    else if(bytes >=10485760 && bytes <= 1073741823){
        float roundFloat = bytes/(1024.0*1024.0);
        return [NSString stringWithFormat:@"%.0fMB",floor(roundFloat)];
    }
    else
        return [NSString stringWithFormat:@"%.1fGB", bytes/(1024.0*1024.0*1024.0)];
}
//show Alerts
+(void)showAlertViewWithTitle:(NSString*)title withMessage:(NSString*)msg delegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title message:msg delegate:delegate cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
    [alert release];
}
+ (BOOL)processStatusCode:(int)sCode{
	NSString *title = @"";
	NSString *message = @"";
	
    BOOL hasError = NO;
    
	if (sCode==500 || sCode==503) {
		title = @"Scheduled maintenance";
		message = @"Scheduled Maintenance. Please try again at a later time, thank you.";
        hasError = YES;
	}else if (sCode==408 || sCode==504){
		title = @"Server timeout";
		message = @"Please check your internet connection and try again.";
        hasError = YES;
	}else if (sCode==401 || sCode==403 || sCode==502){
		title = @"Unauthorized";
		message = @"You do not have permission to perform this action.";
        hasError = YES;
	}else if (sCode==404){
		title = @"File not found";
		message = @"This file doesn't seem to exist on the server anymore.";
        hasError = YES;
	} else if (sCode==405){
		title = @"Unauthorized";
		message = @"Method not allowed.";
        hasError = YES;
	} else if (sCode==409){
		title = @"Unauthorized";
		message = @"Resource conflict.";
        hasError = YES;
	} else if (sCode==429){
		title = @"Unauthorized";
		message = @"client making too many calls and being rate limited.";
        hasError = YES;
	}
	
    if (hasError) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        [alert release];
    }
    if(sCode == 500 ||sCode == 503 || sCode==408 || sCode==504 || sCode == 0)
        return NO;
    else {
        return YES;
    }
}

+ (NSString*)processStatusCodeForDirectoryView:(int)sCode {
	NSString *title;
	
	if (sCode==500 || sCode==503)
		title = @"Scheduled maintenance";
	else if (sCode==408 || sCode==504)
		title = @"Server timeout";
	else if (sCode==401 || sCode==403 || sCode==502){
		title = @"Unauthorized";
    }
	else if (sCode==404)
		title = @"File Unrecognized";
	else
        title = @"Error";
    
    
	return title;
}
/**
 Returns the URL to the application's Documents directory.
 */
+ (NSString *)applicationDocumentsDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
}
//create parent directory based on path
+(void)createParentDirectoryForPath:(NSString*)path {
    NSString *displayedDomain = [DomainPlistHandler getDomainFromPlist];
    NSString *directoryPath = [Utilities applicationDocumentsDirectory];
    directoryPath = [directoryPath stringByAppendingPathComponent:displayedDomain];
    
    NSArray *tempArray = [path componentsSeparatedByString:@"/"];
    int rowNameLength = [[tempArray objectAtIndex:([tempArray count]-1)] length];
    NSString *fileDirPath = [path substringToIndex:([path length]-rowNameLength-1)];
    
    directoryPath = [directoryPath stringByAppendingPathComponent:fileDirPath];
    [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    
}

#pragma mark -
#pragma mark REST API URLs

+(NSURL*)getDirectoryURLForPath:(NSString*)encodedPath {
    NSString *encodedURLString = [[NSString stringWithFormat:@"https://%@/pubapi/v1/fs%@?list_content=true",[DomainPlistHandler getDomainFromPlist],encodedPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:encodedURLString];
    return url;
}
+(NSURL*)getDeleteURLForPath:(NSString*)encodedPath {
    NSString *encodedURLString = [[NSString stringWithFormat:@"https://%@/pubapi/v1/fs%@",[DomainPlistHandler getDomainFromPlist],encodedPath]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:encodedURLString];
    return url;
}

+(NSURL*)getFileByPathURL:(NSString*)absolutePath {
    NSString *encodedURLString = [[NSString stringWithFormat:@"https://%@/pubapi/v1/fs-content%@",[DomainPlistHandler getDomainFromPlist],absolutePath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:encodedURLString];
    return url;
}

+(NSURL*)getFileActionURL:(NSString*)absolutePath {
    NSString *encodedURLString = [[NSString stringWithFormat:@"https://%@/pubapi/v1/fs%@",[DomainPlistHandler getDomainFromPlist],absolutePath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:encodedURLString];
    return url;
}

+(NSURL*)putFileURL:(NSString*)absolutePath {
    NSString *encodedURLString = [[NSString stringWithFormat:@"https://%@/pubapi/v1/fs-content%@",[DomainPlistHandler getDomainFromPlist],absolutePath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSURL *url = [NSURL URLWithString:encodedURLString];
    return url;
}
+(NSURL*)getMobileOAuthURL:(NSString*)ssoDomain {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.%@.com/puboauth/token?client_id=%@&redirect_uri=https://%@&mobile=1",ssoDomain,CONST_APP_SERVER_NAME,OAuth_API_KEY,OAuth_CALLBACK_URL]];
    
    return url;
}

+(BOOL)isDeviceiPhone5 {
    if ([[UIScreen mainScreen] bounds].size.height == 568)
        return YES;
    else
        return NO;
}
@end
