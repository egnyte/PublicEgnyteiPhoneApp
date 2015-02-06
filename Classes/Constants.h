/*
 *  Constants.h
 *  egnyteMobilePhone
 *
 *  Created by Steve Xi Chen on 6/5/10.
 *  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
 *
 */
#import "Utilities.h"

/*
 *
 *
 * Enter your API key in the line below. To request a key, go to Egnyte's Developer Portal at http://developer.egnyte.com
 *
 *
 */
#define OAuth_API_KEY @"PUT_YOUR_KEY_HERE"
/*
 *
 * Enter your API key in the line above. To request a key, go to Egnyte's Developer Portal at http://developer.egnyte.com
 *
 *
 */

#define CONST_APP_SERVER_NAME @"egnyte"
#define CONST_CLIENT_NAME @"iOS LC"
#define CONST_DATE_FORMAT @"MMM dd, YYYY hh:mm a"

#pragma mark -
#pragma mark Folder Permissons constants
#define _R  @"READ"
#define _RW  @"READWRITE"
#define _RWD  @"MODIFY"
#define _REMOVE  @"REMOVE"
#define _ALL  @"ALL"
#define _NAV @"NAV"

#pragma mark -
#pragma mark Folder browsing constants
#define kCellImageViewTag           1000
#define kCellLabelTag               1001
#define kiPhoneLabelIndentedRect					CGRectMake(74.0, 12.0, 215.0, 20.0)
#define kiPhoneLabelRect							CGRectMake(44.0, 12.0, 245.0, 20.0)


#define MOVE_ACTION @"move"
#define COPY_ACTION @"copy"
#define REQUEST_TIMEOUT 33333.0
#define COPY_BTN_TAG  3333
#define MOVE_BTN_TAG  4444
#define DELETE_ALERT 4000

#define FILE_UPLOAD_FAILED_ALERT 2000
#define FILE_UPLOAD_SUCCESS_ALERT 3000


#define OAuth_CALLBACK_URL @"www.egnyte.com"
#define ROW_NAME_LABEL_TAG 1
#define ROW_METADATA_LABEL_TAG 2


