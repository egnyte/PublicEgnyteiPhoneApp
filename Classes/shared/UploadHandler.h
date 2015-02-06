//
//  fileUploader.h
//  egnyteMobilePhone
//
//  Created by Steve Xi Chen on 5/31/10.
//  Copyright 2010 Egnyte Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "Utilities.h"
#import "DomainPlistHandler.h"
#import "MoveCopyHandler.h"

@protocol FileUploadDelegate <NSObject>
@optional
- (void)fileUploaderFinishedListener;
-(void)fileUploaderSuccessfulAlertListenerwithEgyteId:(NSString*)egyteId fileName:(NSString*)fName fileSize:(long)fileSize;
- (void)fileUploaderNOTSuccessfulAlertListener;
@end


@interface UploadHandler : NSObject <UIAlertViewDelegate,UITextFieldDelegate> {
	id <FileUploadDelegate > uploadDelegate;
	NSURLConnection *currentConnection;
	NSString *uploadMediaEId;
	NSString *uploadMediaNote;
	NSString *fileName;
    NSString *filePath;
	NSMutableData *responseData;//NSURLConnection response
    BOOL isErrorInUpload;
}

@property (nonatomic ,retain) NSOperationQueue *uploadFileQueue;
@property (nonatomic, assign) NSURLConnection *currentConnection;
@property (nonatomic, assign) id <NSObject, FileUploadDelegate > uploadDelegate;
@property (nonatomic, retain) NSString *uploadMediaNote;
@property (nonatomic, retain) NSString *uploadMediaEId;
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, assign) long uploadFileSize;

-(void) finishUpload:(Boolean)isDone;
-(void) putFile:(NSString *)fDestDir fileData:(NSData *)fData fileName:(NSString *)fName;
-(void)makeHttpRequestToUploadFileUsingPublicAPI:(NSString *)fdestPath fileData:(NSData*)fileData fileName:(NSString*)fName;
@end
