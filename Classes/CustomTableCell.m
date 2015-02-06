//
//  CustomTableCell.m
//  egnyteMobileIOSUniversal
//
//  Created by Steven Xi Chen on 8/10/11.
//  Copyright © 2008-2012 Egnyte Inc. All Rights Reserved.
//

#import "CustomTableCell.h"
#import "Constants.h"
#import "Utilities.h"

@implementation CustomTableCell
@synthesize namelabel,metaLabel,cellImg;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if(self) {
        if (reuseIdentifier == @"fileCell") {
            CGRect Label1Frame = CGRectMake(44, 0, 340, 25);
            CGRect Label2Frame = CGRectMake(44, 22, 340, 20);
            
            Label1Frame = CGRectMake(44, 0, 270, 25);
            Label2Frame = CGRectMake(44, 22, 270, 20);
            
            //Initialize name Label with tag 1.
            namelabel = [[[UILabel alloc] initWithFrame:Label1Frame] autorelease];
            namelabel.font = [UIFont fontWithName:@"Helvetica" size:16];
            namelabel.tag = ROW_NAME_LABEL_TAG;
            [self.contentView addSubview:namelabel];
            
            //Initialize meta data Label with tag 2.
            metaLabel = [[[UILabel alloc] initWithFrame:Label2Frame] autorelease];
            metaLabel.tag = ROW_METADATA_LABEL_TAG;
            metaLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
            metaLabel.textColor = [UIColor lightGrayColor];
            [self.contentView addSubview:metaLabel];
            
            cellImg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"unselected.png"]] autorelease];
			cellImg.frame = CGRectMake(5.0, 0.0, 30.0, 40.0);
            [self.contentView addSubview:cellImg];
            cellImg.tag =  kCellImageViewTag;
        }else{
            self.accessoryType = UITableViewCellAccessoryNone;
            namelabel = [[[UILabel alloc] initWithFrame:kiPhoneLabelRect] autorelease];
            namelabel.tag = kCellLabelTag;
            [self.contentView addSubview:namelabel];
            
            cellImg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"unselected.png"]] autorelease];
			cellImg.frame = CGRectMake(5.0, 10.0, 30.0, 40.0);
            [self.contentView addSubview:cellImg];
            
            cellImg.tag = kCellImageViewTag;
        }
    };
    
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void)dealloc {
    if (!cellImg)
        [cellImg release];
    if (!namelabel)
        [namelabel release];
    if (!metaLabel)
        [metaLabel release];
    [super dealloc];
}

@end
