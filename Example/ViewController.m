//
//  ViewController.m
//  Example
//
//  Created by Kevin Renskers on 20-08-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "ViewController.h"
#import "LastFm.h"

@interface ViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *loginFormView;
@property (weak, nonatomic) IBOutlet UIView *logoutFormView;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIView *popupView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Check if we're logged in with a valid session
    [[LastFm sharedInstance] getSessionInfoWithSuccessHandler:^(NSDictionary *result) {
        // Yes, show logout form
        [self.logoutButton setTitle:[NSString stringWithFormat:@"Logout %@", [result objectForKey:@"name"]] forState:UIControlStateNormal];
        self.logoutFormView.hidden = NO;
    } failureHandler:^(NSError *error) {
        // No, show login form
        self.loginFormView.hidden = NO;
    }];
}

- (void)viewDidUnload {
    [self setLoginFormView:nil];
    [self setLogoutFormView:nil];
    [self setUsernameField:nil];
    [self setPasswordField:nil];
    [self setPopupView:nil];
    [self setTextView:nil];
    [self setActivityIndicator:nil];
    [self setLogoutButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
        [self.logoutButton setTitle:[NSString stringWithFormat:@"Logout %@", [result objectForKey:@"name"]] forState:UIControlStateNormal];
        self.loginFormView.hidden = YES;
        self.logoutFormView.hidden = NO;
    } failureHandler:^(NSError *error) {
        NSLog(@"Failure: %@", [error localizedDescription]);
    }];
}

- (IBAction)logoutButtonPressed {
    self.loginFormView.hidden = NO;
    self.logoutFormView.hidden = YES;
    [LastFm sharedInstance].session = nil;
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

- (IBAction)artistButtonPressed {
    self.popupView.hidden = NO;
    [self.activityIndicator startAnimating];

    [[LastFm sharedInstance] getInfoForArtist:@"Pink Floyd" successHandler:^(NSDictionary *result) {
        NSLog(@"result: %@", result);
        [self.activityIndicator stopAnimating];
        self.textView.text = [result objectForKey:@"bio"];
    } failureHandler:^(NSError *error) {
        [self.activityIndicator stopAnimating];
        self.textView.text = [NSString stringWithFormat:@"Error: %@", [error localizedDescription]];
    }];
}

- (IBAction)closePopupButtonPressed {
    self.popupView.hidden = YES;
}

@end
