//
//  DetailViewController.m
//  Example
//
//  Created by Kevin Renskers on 31-10-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "DetailViewController.h"
#import "LastFm.h"
#import "UIImageView+WebCache.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *scrobblesLabel;
@property (weak, nonatomic) IBOutlet UILabel *personalScrobblesLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSURL *url;
@end

@implementation DetailViewController

- (void)viewWillAppear:(BOOL)animated {
    self.title = self.artist;

    self.scrobblesLabel.text = @"";
    self.personalScrobblesLabel.text = @"";

    [[LastFm sharedInstance] getInfoForArtist:self.artist successHandler:^(NSDictionary *result) {
        [self.webView loadHTMLString:[result objectForKey:@"bio"] baseURL:nil];
        self.artistLabel.text = [result objectForKey:@"name"];
        self.scrobblesLabel.text = [NSString stringWithFormat:@"%@ global scrobbles", [result objectForKey:@"playcount"]];

        if ([LastFm sharedInstance].session) {
            self.personalScrobblesLabel.text = [NSString stringWithFormat:@"%@ personal scrobbles", [result objectForKey:@"userplaycount"]];
        }

        NSURL *image = [result objectForKey:@"image"];
        if (image) {
            [self.imageView setImageWithURL:image placeholderImage:[UIImage imageNamed:@"Icon"]];
        }
    } failureHandler:nil];
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [self setArtistLabel:nil];
    [self setScrobblesLabel:nil];
    [self setImageView:nil];
    [self setPersonalScrobblesLabel:nil];
    [super viewDidUnload];
}

@end
