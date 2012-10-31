//
//  DetailViewController.m
//  Example
//
//  Created by Kevin Renskers on 31-10-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "DetailViewController.h"
#import "LastFm.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation DetailViewController

- (void)viewWillAppear:(BOOL)animated {
    self.title = self.artist;
    [[LastFm sharedInstance] getInfoForArtist:self.artist successHandler:^(NSDictionary *result) {
        [self.webView loadHTMLString:[result objectForKey:@"bio"] baseURL:nil];
    } failureHandler:nil];
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [super viewDidUnload];
}

@end
