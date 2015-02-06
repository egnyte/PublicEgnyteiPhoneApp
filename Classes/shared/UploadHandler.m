//
//  fileUploader.m
//  egnyteMobilePhone
//
//  Created by Steve Xi Chen on 5/31/10.
//  Copyright 2010 Egnyte Inc. All rights reserved.
//

#import "UploadHandler.h"
#import <AVFoundation/AVAssetExportSession.h>
@implementation UploadHandler
@synthesize uploadDelegate;
@synthesize uploadMediaNote,uploadMediaEId,currentConnection,fileName,uploadFileSize,filePath;

-(id)init {
    
	if(self=[super init]) {
		
	}
	return self;
}

-(void) putFile:(NSString *)fDestDir fileData:(NSData *)fData fileName:(NSString *)fName {
    self.fileName = fName;
    
    // make file upload HTTP request
    [self makeHttpRequestToUploadFileUsingPublicAPI:fDestDir fileData:fData fileName:fName];
    
}
-(void)makeHttpRequestToUploadFileUsingPublicAPI:(NSString *)fdestPath fileData:(NSData*)fileData fileName:(NSString*)fName {
    
    NSURL *theURL = [Utilities putFileURL:[NSString stringWithFormat:@"%@/%@",fdestPath,fName]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: theURL
                                                           cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval: 33333.0];
    [Utilities setUniversalPOSTRequestHeaders:request];
    [request setValue:[Utilities getMimeType:fName] forHTTPHeaderField:@"Content-Type"];

    //set file data as HTTP Body
    [request setHTTPBody:fileData];
    self.uploadFileSize = [fileData length];
    NSLog(@"%@",[request allHTTPHeaderFields]);
    [[NSURLConnection alloc]initWithRequest:request delegate:self];
}

#pragma mark NSURLConnection delegate methods
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	currentConnection = connection;
	
	return request;
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self finishUpload:NO];
	currentConnection = nil;
	return ;
}

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response {
	
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        int statusCode = (int)[(NSHTTPURLResponse*) response statusCode];
		NSDictionary *headerFields=[(NSHTTPURLResponse*) response allHeaderFields];
		if(statusCode == 200) {
            //grap Egnyte Id for successfully uplaoded file from response header
			self.uploadMediaEId=[headerFields objectForKey:@"Etag"];
			[uploadMediaEId retain];
            isErrorInUpload = NO;
			[self finishUpload:YES];
        }else if (statusCode != 200) {
            //failure file upload
            isErrorInUpload = YES;
            [uploadDelegate fileUploaderNOTSuccessfulAlertListener];
		}
    }
	
	return;
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    if(isErrorInUpload == YES) {
        //didReceiveData only when there is error
        //this is how you would process an error message
        NSString* receiveStr = [[[NSString alloc] initWithData:data
                                                      encoding:NSUTF8StringEncoding] autorelease];
        //best way to do this is to parse it with JSON library
        [Utilities showAlertViewWithTitle:@"File upload Error" withMessage:receiveStr delegate:nil];
    }
}
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	//file upload completed with HTTP success
	currentConnection = nil;
	return;
}
#pragma mark -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//inside file upload alertview button click
    
	if (alertView.tag == FILE_UPLOAD_SUCCESS_ALERT){
		// file upload successful
		if(self.uploadMediaEId != nil) {
            [uploadDelegate fileUploaderSuccessfulAlertListenerwithEgyteId:self.uploadMediaEId fileName:self.fileName fileSize:self.uploadFileSize];
		}
	} else if (alertView.tag == FILE_UPLOAD_FAILED_ALERT) {
        //file upload failed
		[uploadDelegate fileUploaderNOTSuccessfulAlertListener];
	}
}


-(void)finishUpload:(Boolean)isDone{
    
    [uploadDelegate fileUploaderFinishedListener];
	
    if(isDone){
        //file upload successful alert
		UIAlertView *doneAlert = [[UIAlertView alloc] initWithTitle:@"File uploaded successfully." message:@" "
														   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        doneAlert.tag = FILE_UPLOAD_SUCCESS_ALERT;
		[doneAlert show];
		[doneAlert release];
        
	} else if(!isDone) {
        //file upload failed alert
        UIAlertView *failedAlert = [[UIAlertView alloc]initWithTitle:[NSString stringWithFormat:@"File upload failed for:%@",self.fileName] message:@"Please try again. If you have any questions, email us or please call: 1-650-265-4058" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        failedAlert.tag = FILE_UPLOAD_FAILED_ALERT;
        [failedAlert show];
        [failedAlert release];
	}
}

@end
