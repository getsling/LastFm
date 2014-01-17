//
//  ArtistCell.m
//  Example
//
//  Created by Kevin Renskers on 31-10-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import <LastFm/LastFm.h>
#import "ArtistCell.h"
#import "UIImageView+WebCache.h"

@interface ArtistCell ()
@property (strong, nonatomic) NSOperation *operation;
@end

@implementation ArtistCell

- (void)loadLastFmDataForArtist:(NSString *)artist {
    self.textLabel.text = artist;
    self.detailTextLabel.text = @"loading...";

    self.operation = [[LastFm sharedInstance] getInfoForArtist:artist successHandler:^(NSDictionary *result) {
        // This check is necessary because the successHandler might be called when the cell is
        // already being reused for another artist!
        if ([artist isEqualToString:[[result objectForKey:@"_params"] objectForKey:@"artist"]]) {
            NSURL *image = [result objectForKey:@"image"];
            if (image) {
                [self.imageView setImageWithURL:image placeholderImage:[UIImage imageNamed:@"Icon"]];
            }
            self.detailTextLabel.text = [NSString stringWithFormat:@"%@ scrobbles", [result objectForKey:@"playcount"]];
        }
    } failureHandler:nil];
}

- (void)prepareForReuse {
    [self.operation cancel];
    [self.imageView cancelCurrentImageLoad];
    [super prepareForReuse];
}

@end
