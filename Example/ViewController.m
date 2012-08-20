//
//  ViewController.m
//  Example
//
//  Created by Kevin Renskers on 20-08-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "ViewController.h"
#import "LastFm.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[LastFm sharedInstance] getInfoForArtist:@"Pink Floyd" successHandler:^(NSDictionary *result) {
        NSLog(@"result: %@", result);
    } failureHandler:^(NSError *error) {
        NSLog(@"error: %@", error);
    }];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
