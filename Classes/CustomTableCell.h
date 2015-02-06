//
//  CustomTableCell.h
//  egnyteMobileIOSUniversal
//
//  Created by Steven Xi Chen on 8/10/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import <Foundation/Foundation.h>


@interface CustomTableCell : UITableViewCell {
    IBOutlet UILabel *namelabel;
	IBOutlet UILabel *metaLabel;
	IBOutlet UIImageView *cellImg;
    
}

@property(nonatomic,retain)IBOutlet UILabel *namelabel;
@property(nonatomic,retain)IBOutlet UILabel *metaLabel;
@property(nonatomic,retain)IBOutlet UIImageView *cellImg;

@end
