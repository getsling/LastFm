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
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (strong, nonatomic) NSURL *url;
@end

@implementation DetailViewController

- (void)viewWillAppear:(BOOL)animated {
    self.title = self.artist;

    self.button.enabled = NO;

    [[LastFm sharedInstance] getInfoForArtist:self.artist successHandler:^(NSDictionary *result) {
        [self.webView loadHTMLString:[result objectForKey:@"bio"] baseURL:nil];
        self.artistLabel.text = [result objectForKey:@"name"];
        self.scrobblesLabel.text = [NSString stringWithFormat:@"%@ scrobbles", [result objectForKey:@"playcount"]];

        NSURL *image = [result objectForKey:@"image"];
        if (image) {
            [self.imageView setImageWithURL:image placeholderImage:[UIImage imageNamed:@"Icon"]];
        }

        self.url = [result objectForKey:@"url"];
        if (self.url) {
            self.button.enabled = YES;
        }
    } failureHandler:nil];
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [self setArtistLabel:nil];
    [self setScrobblesLabel:nil];
    [self setImageView:nil];
    [self setButton:nil];
    [super viewDidUnload];
}

- (IBAction)openUrlButtonPressed {
    NSLog(@"url: %@", [self.url absoluteString]);
}

@end
