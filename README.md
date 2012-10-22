# LastFm - block based Last.fm SDK for iOS and Mac OS X

Loosely based on LastFMService from the [official Last.fm iPhone app](https://github.com/lastfm/lastfm-iphone/blob/master/Classes/LastFMService.m), but non-blocking, more readable, much easier to use (and to extend) and with less dependencies.

### Features
- Block based for easier usage
- Only one dependency ([KissXML](https://github.com/robbiehanson/KissXML))
- Returns values in the correct data type (NSDate, NSURL, NSNumber, etc)
- Actively developed and maintained (note: at the moment **backwards-incompatible changes are to be expected**)


## Usage
```objective-c
// Set the Last.fm session info
[LastFm sharedInstance].apiKey = @"xxx";
[LastFm sharedInstance].apiSecret = @"xxx";
[LastFm sharedInstance].session = session;
[LastFm sharedInstance].username = username;

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

// Scrobble a track
[[LastFm sharedInstance] sendScrobbledTrack:@"Wish You Were Here" byArtist:@"Pink Floyd" onAlbum:@"Wish You Were Here" withDuration:534 atTimestamp:(int)[[NSDate date] timeIntervalSince1970] successHandler:^(NSDictionary *result) {
    NSLog(@"result: %@", result);
} failureHandler:^(NSError *error) {
    NSLog(@"error: %@", error);
}];
```

Save the username and session you get with `getSessionForUser:password:successHandler:failureHandler:` somewhere, for example in `NSUserDefaults`, and on app start up set it back on `[LastFm sharedInstance].username` and `[LastFm sharedInstance].session`.

See the included iOS project for examples on login, logout, getting artist info and more.


## Installation
You can install LastFm with [CocoaPods](http://cocoapods.org). You can also get the code and drag the LastFm subfolder into your Xcode project.

### Requirements
* LastFm is built using ARC and modern Objective-C syntax. You will need Xcode 4.4 or higher to use it in your project.
* You will need your own API key by registering at http://www.last.fm/api.
* [KissXML](https://github.com/robbiehanson/KissXML)

### Caching
If you want all GET requests to be cached as aggressively as possible, install [SDURLCache](https://github.com/rs/SDURLCache/) (or steipete's [ARC fork](https://github.com/steipete/SDURLCache/)). Then, add the following code to your app delegate's `application:didFinishLaunchingWithOptions:` method:

```objective-c
SDURLCache *URLCache = [[SDURLCache alloc] initWithMemoryCapacity:10 * 1024 * 1024
                                                     diskCapacity:50 * 1024 * 1024
                                                         diskPath:[SDURLCache defaultCachePath]];
[NSURLCache setSharedURLCache:URLCache];
````


## Issues and questions
Have a bug? Please [create an issue on GitHub](https://github.com/gangverk/LastFm/issues)!


## License
LastFm is available under the MIT license. See the LICENSE file for more info.
