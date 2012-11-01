//
//  ViewController.m
//  Example
//
//  Created by Kevin Renskers on 20-08-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "ViewController.h"
#import "LastFm.h"
#import "UIImageView+WebCache.h"
#import "ArtistCell.h"
#import "DetailViewController.h"

@interface ViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIView *loginFormView;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *artists;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Check if we're logged in with a valid session
    [[LastFm sharedInstance] getSessionInfoWithSuccessHandler:^(NSDictionary *result) {
        [self.loginButton setTitle:[NSString stringWithFormat:@"Logout %@", [result objectForKey:@"name"]]];
        [self.loginButton setAction:@selector(logout)];
    } failureHandler:^(NSError *error) {
        // No, show login form
        [self.loginButton setTitle:@"Login"];
        [self.loginButton setAction:@selector(showLoginForm)];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewDidUnload {
    [self setLoginFormView:nil];
    [self setUsernameField:nil];
    [self setPasswordField:nil];
    [self setLoginButton:nil];
    [self setTableView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)showLoginForm {
    self.loginFormView.hidden = NO;
}

- (IBAction)hideLoginForm {
    self.loginFormView.hidden = YES;
}

- (IBAction)loginButtonPressed {
    [[LastFm sharedInstance] getSessionForUser:self.usernameField.text password:self.passwordField.text successHandler:^(NSDictionary *result) {
        // Save the session into NSUserDefaults. It is loaded on app start up in AppDelegate.
        [[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:@"key"] forKey:SESSION_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:@"name"] forKey:USERNAME_KEY];

        // Also set the session of the LastFm object
        [LastFm sharedInstance].session = [result objectForKey:@"key"];
        [LastFm sharedInstance].username = [result objectForKey:@"name"];

        // Dismiss the keyboard
        [self.usernameField resignFirstResponder];
        [self.passwordField resignFirstResponder];

        // Show the logout button
        [self.loginButton setTitle:[NSString stringWithFormat:@"Logout %@", [result objectForKey:@"name"]]];
        [self.loginButton setAction:@selector(logout)];
        self.loginFormView.hidden = YES;
    } failureHandler:^(NSError *error) {
        NSLog(@"Failure: %@", [error localizedDescription]);
    }];
}

- (void)logout {
    [self.loginButton setTitle:@"Login"];
    [self.loginButton setAction:@selector(showLoginForm)];
    [[LastFm sharedInstance] logout];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SESSION_KEY];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self loginButtonPressed];
    }

    return YES;
}

#pragma mark - Table

- (NSArray *)artists {
    if (!_artists) {
        _artists = @[
            @"The Beatles", @"Air", @"Pink Floyd", @"Rammstein", @"Bloodhound Gang",
            @"Ancien Régime", @"Genius/GZA ", @"Belle & Sebastian", @"Björk",
            @"Ugress", @"ADELE", @"The Asteroids Galaxy Tour", @"Bar 9",
            @"Baskerville", @"Beastie Boys", @"Bee Gees", @"Bit Shifter",
            @"Bomfunk MC's", @"C-Mon & Kypski", @"The Cardigans", @"Carly Commando",
            @"Caro Emerald", @"Coldplay", @"Coolio", @"Cypress Hill",
            @"David Bowie", @"Deadmau5", @"Dukes of Stratosphear", @"[dunkelbunt]",
            @"Eminem", @"Enigma",
        ];
    }
    return _artists;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.artists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ArtistCell";
    ArtistCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    NSString *artist = [self.artists objectAtIndex:indexPath.row];
    [cell loadLastFmDataForArtist:artist];

    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(ArtistCell *)sender {
    DetailViewController *detailViewController = (DetailViewController *)segue.destinationViewController;
    detailViewController.artist = sender.textLabel.text;
}

@end
