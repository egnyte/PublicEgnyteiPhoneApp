//
//  DomainPlistHandler.h
//  egnyteMobilePad
//
//  Created by Steve Xi Chen on 6/28/10.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
@interface DomainPlistHandler : NSObject { }

+(NSString *)getDomainFromPlist;
+(NSString *)getAccessTokenFromPlist;

+(void)writeAccessTokenToPlist:(NSString *)pswd;
+(void)resetDefaultDomain;
+(void)writeDomainToPlist:(NSString *)domainName;
+(NSString*)getOAuthTokenTypeFromPlist;
+(void)writeOAuthTokenType:(NSString *)tokenType;



@end
