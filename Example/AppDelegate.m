//
//  AppDelegate.m
//  Example
//
//  Created by Kevin Renskers on 20-08-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "AppDelegate.h"
#import "LastFm.h"
#import "ViewController.h"
#import "LastFmCache.h"
#import "SDURLCache.h"

@interface AppDelegate ()
@property (strong, nonatomic) LastFmCache *lastFmCache;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Setup NSURLCache
    SDURLCache *URLCache = [[SDURLCache alloc] initWithMemoryCapacity:10 * 1024 * 1024
                                                         diskCapacity:50 * 1024 * 1024
                                                             diskPath:[SDURLCache defaultCachePath]];
    [NSURLCache setSharedURLCache:URLCache];

    self.lastFmCache = [[LastFmCache alloc] init];

    // Setup the Last.fm SDK
    // IMPORTANT: please register your own API key at http://www.last.fm/api - don't use this key!
    [LastFm sharedInstance].apiKey = @"349b1b1344545e7c7832d0c2a91f44fe";
    [LastFm sharedInstance].apiSecret = @"d2a6f3aa73d473d989118e9430a36608";
    [LastFm sharedInstance].session = [[NSUserDefaults standardUserDefaults] stringForKey:SESSION_KEY];
    [LastFm sharedInstance].username = [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME_KEY];
    [LastFm sharedInstance].cacheDelegate = self.lastFmCache;

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
