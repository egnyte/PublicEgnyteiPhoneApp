
//
//  domainPlistHandler.m
//  egnyteMobilePad
//
//  Created by Steve Xi Chen on 6/28/10.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import "DomainPlistHandler.h"
#define DISPLAY_EGNYTE_DOMAIN_KEY @"displayedDomain"


@implementation DomainPlistHandler


+(void)resetDefaultDomain{
	//resetting default domain on logout
	NSString *documentsDirectory = [Utilities applicationDocumentsDirectory];
	NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"egnyteDomain.plist"];
	
	NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile: plistPath];
	
    //here add elements to data file and write data to file
	[data setObject:[NSString stringWithFormat:@"yourdomain"] forKey:@"domainName"];
	[data setObject:[NSString stringWithFormat:@""] forKey:@"accessToken"];
    
    [data writeToFile:plistPath atomically:YES];
	
    [data release];
}

+(void)writeDomainToPlist:(NSString *)domainName{
	NSString *documentsDirectory = [Utilities applicationDocumentsDirectory];
	NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"egnyteDomain.plist"];
	NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile: plistPath];
	
	[data setObject:domainName forKey:@"domainName"];
    [data writeToFile:plistPath atomically:NO];
	
    [data release];
	
}

+(void)writeAccessTokenToPlist :(NSString *)pswd {
	NSString *documentsDirectory = [Utilities applicationDocumentsDirectory];
	NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"egnyteDomain.plist"];
	
	NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile: plistPath];
	
    //here add elements to data file and write data to file
	[data setObject:pswd forKey:@"accessToken"];
    [data writeToFile:plistPath atomically:NO];
	
    [data release];
}

+(NSString *)getAccessTokenFromPlist {
    
	NSError *error;
	NSString *documentsDirectory = [Utilities applicationDocumentsDirectory];
	NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"egnyteDomain.plist"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (![fileManager fileExistsAtPath: plistPath]){
		NSString *bundle = [[NSBundle mainBundle] pathForResource:@"egnyteDomain" ofType:@"plist"];
		[fileManager copyItemAtPath:bundle toPath: plistPath error:&error];
	}
	
	//read plist
    NSDictionary *savedStock = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	//load from savedStock example int value
	return [savedStock objectForKey:@"accessToken"];
}

+(NSString *)getDomainFromPlist {
	NSError *error;
	NSString *documentsDirectory = [Utilities applicationDocumentsDirectory];
	NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"egnyteDomain.plist"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (![fileManager fileExistsAtPath: plistPath]){
		NSString *bundle = [[NSBundle mainBundle] pathForResource:@"egnyteDomain" ofType:@"plist"];
		[fileManager copyItemAtPath:bundle toPath: plistPath error:&error];
	}
	
	////read plist
    NSDictionary *savedStock = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	//load from savedStock example int value
	return [savedStock objectForKey:@"domainName"];
}


+(void)writeOAuthTokenType:(NSString *)tokenType {
	NSString *documentsDirectory = [Utilities applicationDocumentsDirectory];
	NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"egnyteDomain.plist"];
	
	NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile: plistPath];
	
    //here add elements to data file and write data to file
	[data setObject:tokenType forKey:@"token_type"];
    
    [data writeToFile:plistPath atomically:NO];
	
    [data release];
}
+(NSString*)getOAuthTokenTypeFromPlist{
	NSError *error;
	NSString *documentsDirectory = [Utilities applicationDocumentsDirectory];
	NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"egnyteDomain.plist"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (![fileManager fileExistsAtPath: plistPath]){
		NSString *bundle = [[NSBundle mainBundle] pathForResource:@"egnyteDomain" ofType:@"plist"];
		[fileManager copyItemAtPath:bundle toPath: plistPath error:&error];
	}
	
	//read plist
    NSDictionary *savedStock = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	//load from savedStock example int value
	return [savedStock objectForKey:@"token_type"];
}



-(void)dealloc {
	[super dealloc];
}
@end
