# LastFm

Last.fm SDK for iOS


## Usage

    // Set the Last.fm session info
    [LastFm sharedInstance].api_key = @"b25b959554ed76058ac220b7b2e0a026";
    [LastFm sharedInstance].api_secret = @"xxx";
    [LastFm sharedInstance].session = session;

    // Get artist info
    [[LastFm sharedInstance] getInfoForArtist:@"Pinn Floyd" successHandler:^(NSDictionary *result) {
        NSLog(@"result: %@", result);
    } failureHandler:^(NSError *error) {
        NSLog(@"error: %@", error);
    }];

	// Get images for an artist
    [[LastFm sharedInstance] getImagesForArtist:@"Cher" successHandler:^(NSArray *result) {
        NSLog(@"result: %@", result);
    } failureHandler:^(NSError *error) {
        NSLog(@"error: %@", error);
    }];

Save the session you get with `getSessionForUser:password:successHandler:failureHandler:` somewhere, for example in `NSUserDefaults`, and on app start up set it back on `[LastFm sharedInstance].session`.


## Issues and questions
Have a bug? Please create an issue on GitHub!

https://github.com/gangverk/LastFm/issues


## License
LastFm is available under the MIT license. See the LICENSE file for more info.