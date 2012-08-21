# LastFm

Last.fm SDK for iOS


## Usage
```objective-c
// Set the Last.fm session info
[LastFm sharedInstance].apiKey = @"xxx";
[LastFm sharedInstance].apiSecret = @"xxx";
[LastFm sharedInstance].session = session;

// Get artist info
[[LastFm sharedInstance] getInfoForArtist:@"Pink Floyd" successHandler:^(NSDictionary *result) {
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
```

Save the session you get with `getSessionForUser:password:successHandler:failureHandler:` somewhere, for example in `NSUserDefaults`, and on app start up set it back on `[LastFm sharedInstance].session`.


## Requirements
* LastFm is built using ARC and modern Objective-C syntax. You will need Xcode 4.4 or higher to use it in your project.
* You will need your own API key by registering at http://www.last.fm/api.
* [KissXML](https://github.com/robbiehanson/KissXML)


## Issues and questions
Have a bug? Please [create an issue on GitHub](https://github.com/gangverk/LastFm/issues)!


## License
LastFm is available under the MIT license. See the LICENSE file for more info.