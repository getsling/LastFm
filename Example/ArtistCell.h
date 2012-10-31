//
//  ArtistCell.h
//  Example
//
//  Created by Kevin Renskers on 31-10-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArtistCell : UITableViewCell
- (void)loadLastFmDataForArtist:(NSString *)artist;
@end
