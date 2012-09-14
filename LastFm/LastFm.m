//
//  LastFm.m
//  lastfmlocalplayback
//
//  Created by Kevin Renskers on 17-08-12.
//  Copyright (c) 2012 Last.fm. All rights reserved.
//

#import "LastFm.h"
#import "DDXML.h"
#include <CommonCrypto/CommonDigest.h>

#define API_URL @"http://ws.audioscrobbler.com/2.0/"

@interface DDXMLNode (objectAtXPath)
- (id)objectAtXPath:(NSString *)XPath;
@end

@implementation DDXMLNode (objectAtXPath)

- (id)objectAtXPath:(NSString *)XPath {
    NSError *err;
    NSArray *nodes = [self nodesForXPath:XPath error:&err];

    if ([nodes count]) {
        NSMutableArray *strings = [[NSMutableArray alloc] init];
        for (DDXMLNode *node in nodes) {
            if ([node stringValue]) {
                [strings addObject:[[node stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            }
        }
        if ([strings count] == 1) {
            NSString *output = [NSString stringWithString:[strings objectAtIndex:0]];
            return output;
        } else if ([strings count] > 1) {
            return strings;
        } else {
            return @"";
        }
    } else {
        return @"";
    }
}

@end


@interface LastFm ()
@property (nonatomic, strong) NSOperationQueue *queue;
@end


@implementation LastFm

+ (LastFm *)sharedInstance {
    static dispatch_once_t pred;
    static LastFm *sharedInstance = nil;
    dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.apiKey = @"";
        self.apiSecret = @"";
        self.queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

#pragma mark - Private methods

- (NSString *)md5sumFromString:(NSString *)string {
	unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
	CC_MD5([string UTF8String], [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
	NSMutableString *ms = [NSMutableString string];
	for (i=0;i<CC_MD5_DIGEST_LENGTH;i++) {
		[ms appendFormat: @"%02x", (int)(digest[i])];
	}
	return [ms copy];
}

- (NSString*)urlEscapeString:(id)unencodedString {
    if ([unencodedString isKindOfClass:[NSString class]]) {
        CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
        NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
        CFRelease(originalStringRef);
        return s;
    }
    return unencodedString;
}

- (void)performApiCallForMethod:(NSString*)method
                     withParams:(NSDictionary *)params
                      rootXpath:(NSString *)rootXpath
               returnDictionary:(BOOL)returnDictionary
                  mappingObject:(NSDictionary *)mappingObject
                 successHandler:(LastFmReturnBlockWithObject)successHandler
                 failureHandler:(LastFmReturnBlockWithError)failureHandler {

    NSBlockOperation *op = [[NSBlockOperation alloc] init];
    [op addExecutionBlock:^{
        NSMutableDictionary *newParams = [params mutableCopy];
        [newParams setObject:method forKey:@"method"];
        [newParams setObject:self.apiKey forKey:@"api_key"];

        if (self.session) {
            [newParams setObject:self.session forKey:@"sk"];
        }

        // Create signature. This is annoying, we need to sort all the params
        NSArray *sortedParamKeys = [[newParams allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSMutableString *signature = [[NSMutableString alloc] init];
        for (NSString *key in sortedParamKeys) {
            [signature appendString:[NSString stringWithFormat:@"%@%@", key, [newParams objectForKey:key]]];
        }
        [signature appendString:self.apiSecret];

        // We even need to *send* all the params in a sorted fashion
        NSMutableArray *sortedParamsArray = [NSMutableArray array];
        for (NSString *key in sortedParamKeys) {
            [sortedParamsArray addObject:[NSString stringWithFormat:@"&%@=%@", [self urlEscapeString:key], [self urlEscapeString:[newParams objectForKey:key]]]];
        }

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:API_URL]];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[[NSString stringWithFormat:@"%@&api_sig=%@", [sortedParamsArray componentsJoinedByString:@"&"], [self md5sumFromString:signature]] dataUsingEncoding:NSUTF8StringEncoding]];

        NSURLResponse *response;
        NSError *error;

        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

        if (error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                failureHandler(error);
            }];
            return;
        }

        DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];

        if (error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                failureHandler(error);
            }];
            return;
        }

        if (![[[document rootElement] objectAtXPath:@"./@status"] isEqualToString:@"ok"]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSError *lastfmError = [[NSError alloc] initWithDomain:LastFmServiceErrorDomain
                                                   code:[[[document rootElement] objectAtXPath:@"./error/@code"] intValue]
                                               userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[[document rootElement] objectAtXPath:@"./error"], NSLocalizedDescriptionKey, method, @"method", nil]];

                failureHandler(lastfmError);
            }];
            return;
        }

        NSArray *output = [[document rootElement] nodesForXPath:rootXpath error:&error];
        NSMutableArray *returnArray = [NSMutableArray array];

        for (DDXMLNode *node in output) {
            // Convert this node to a dictionary using the mapping object (keys and xpaths)
            NSMutableDictionary *result = [NSMutableDictionary dictionary];

            for (NSString *key in mappingObject) {
                NSString *xpath = [mappingObject objectForKey:key];
                [result setObject:[node objectAtXPath:xpath] forKey:key];
            }

            // If the string "startDate" exists, then convert it into an NSDate, saved as "startNSDate"
            if ([result objectForKey:@"startDate"]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
                [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss"]; //"Fri, 21 Jan 2011 21:00:00"

                NSDate *date = [formatter dateFromString:[result objectForKey:@"startDate"]];
                [result setObject:date forKey:@"startNSDate"];
            }

            [returnArray addObject:result];
        }

        if (returnArray && returnArray.count) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (returnDictionary) {
                    successHandler([returnArray objectAtIndex:0]);
                } else {
                    successHandler(returnArray);
                }
            }];
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (failureHandler) {
                    failureHandler(error);
                }
            }];
        }
    }];

    [self.queue addOperation:op];
}

#pragma mark -
#pragma mark Artist methods

- (void)getInfoForArtist:(NSString *)artist fromUserOrNil:(NSString *)user successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"bio": @"./bio/content",
        @"summary": @"./bio/summary",
        @"name": @"./name",
        @"url": @"./url",
        @"image": @"./image[@size=\"large\"]",
        @"listeners": @"./stats/listeners",
        @"playcount": @"./stats/playcount",
        @"userplaycount": @"./stats/userplaycount"
    };

    NSDictionary *params;
    if (user) {
        params = @{@"artist": artist, @"username": user};
    } else {
        params = @{@"artist": artist};
    }

    [self performApiCallForMethod:@"artist.getInfo"
                       withParams:params
                        rootXpath:@"./artist"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getEventsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"title": @"./title",
        @"headliner": @"./artists/headliner",
        @"attendance": @"./attendance",
        @"description": @"./description",
        @"startDate": @"./startDate",
        @"url": @"./url",
        @"image": @"./image[@size=\"large\"]",
        @"venue": @"./venue/name",
        @"city": @"./venue/location/city",
        @"country": @"./venue/location/country",
        @"venue_url": @"./venue/website"
    };

    [self performApiCallForMethod:@"artist.getEvents"
                       withParams:@{@"artist": artist}
                        rootXpath:@"./events/event"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getTopAlbumsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"artist": @"./artist/name",
        @"title": @"./name",
        @"playcount": @"./playcount",
        @"url": @"./url",
        @"image": @"./image[@size=\"large\"]"
    };

    [self performApiCallForMethod:@"artist.getTopAlbums"
                       withParams:@{@"artist": artist, @"limit": @"500"}
                        rootXpath:@"./topalbums/album"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getTopTracksForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @"./name",
        @"playcount": @"./playcount",
        @"image": @"./image[@size=\"large\"]"
    };

    [self performApiCallForMethod:@"artist.getTopTracks"
                       withParams:@{@"artist": artist, @"limit": @"500"}
                        rootXpath:@"./toptracks/track"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getImagesForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"format": @"format",
        @"original": @"./sizes/size[@name=\"original\"]",
        @"extralarge": @"./sizes/size[@name=\"extralarge\"]",
        @"large": @"./sizes/size[@name=\"large\"]",
        @"largesquare": @"./sizes/size[@name=\"largesquare\"]",
        @"medium": @"./sizes/size[@name=\"medium\"]",
        @"small": @"./sizes/size[@name=\"small\"]",
        @"title": @"title",
        @"utl": @"url",
        @"tags": @"./tags/tag/name"
    };

    [self performApiCallForMethod:@"artist.getImages"
                       withParams:@{@"artist": artist, @"limit": @"500"}
                        rootXpath:@"./images/image"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];

}

- (void)getSimilarArtistsTo:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @"./name",
        @"match": @"./match",
        @"image": @"./image[@size=\"large\"]"
    };

    [self performApiCallForMethod:@"artist.getSimilar"
                       withParams:@{@"artist": artist, @"limit": @"500"}
                        rootXpath:@"./similarartists/artist"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark Album methods

- (void)getInfoForAlbum:(NSString *)album artist:(NSString *)artist fromUserOrNil:(NSString *)user successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"artist": @"./artist",
        @"name": @"./name",
        @"listeners": @"./listeners",
        @"playcount": @"./playcount",
        @"url": @"./url",
        @"image": @"./image[@size=\"large\"]",
        @"releasedate": @"./releasedate",
        @"tags": @"./toptags/tag/name",
        @"userplaycount": @"./userplaycount"
    };

    NSDictionary *params;
    if (user) {
        params = @{@"artist": artist, @"album": album, @"username": user};
    } else {
        params = @{@"artist": artist, @"album": album};
    }

    [self performApiCallForMethod:@"album.getInfo"
                       withParams:@{@"artist": artist, @"album": album}
                        rootXpath:@"./album"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getTracksForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"rank": @"@rank",
        @"artist": @"./artist/name",
        @"name": @"./name",
        @"duration": @"./duration",
        @"url": @"./url"
    };

    [self performApiCallForMethod:@"album.getInfo"
                       withParams:@{@"artist": artist, @"album": album}
                        rootXpath:@"./album/tracks/track"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark Track methods

- (void)getInfoForTrack:(NSString *)title artist:(NSString *)artist fromUserOrNil:(NSString*)user successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @"./name",
        @"listeners": @"./listeners",
        @"playcount": @"./playcount",
        @"tags": @"./toptags/tag/name",
        @"artist": @"./artist/name",
        @"album": @"./album/title",
        @"image": @"./album/image[@size=\"large\"]",
        @"wiki": @"./wiki/summary",
        @"duration": @"./duration",
        @"userplaycount": @"./userplaycount",
        @"userloved": @"./userloved"
    };

    NSDictionary *params;
    if (user) {
        params = @{@"track": title, @"artist": artist, @"username": user};
    } else {
        params = @{@"track": title, @"artist": artist};
    }

    [self performApiCallForMethod:@"track.getInfo"
                       withParams:params
                        rootXpath:@"./track"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getInfoForTrack:(NSString *)musicBrainId fromUserOrNil:(NSString *)user successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @"./name",
        @"listeners": @"./listeners",
        @"playcount": @"./playcount",
        @"userplaycount": @"./userplaycount",
        @"tags": @"./toptags/tag/name",
        @"artist": @"./artist/name",
        @"album": @"./album/title",
        @"image": @"./album/image[@size=\"large\"]",
        @"wiki": @"./wiki/summary",
        @"duration": @"./duration"
    };

    NSDictionary *params;
    if (user) {
        params = @{@"mbid": musicBrainId, @"username": user};
    } else {
        params = @{@"mbid": musicBrainId};
    }

    [self performApiCallForMethod:@"track.getInfo"
                       withParams:params
                        rootXpath:@"./track"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark User methods

- (void)getSessionForUser:(NSString *)username password:(NSString *)password successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSString *authToken = [self md5sumFromString:[NSString stringWithFormat:@"%@%@", [username lowercaseString], [self md5sumFromString:password]]];

    NSDictionary *mappingObject = @{
        @"key": @"./key",
        @"subscriber": @"./subscriber"
    };

    [self performApiCallForMethod:@"auth.getMobileSession"
                       withParams:@{@"username": [username lowercaseString], @"authToken": authToken}
                        rootXpath:@"./session"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getSessionInfoWithSuccessHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"subscriber": @"./session/subscriber",
        @"country": @"./country",
        @"radio_enabled": @"./radioPermission/user[@type=\"you\"]/radio",
        @"trial_enabled": @"./radioPermission/user[@type=\"you\"]/freetrial",
        @"trial_expired": @"./radioPermission/user[@type=\"you\"]/trial/expired",
        @"trial_playsleft": @"./radioPermission/user[@type=\"you\"]/trial/playsleft",
        @"trial_playselapsed": @"./radioPermission/user[@type=\"you\"]/trial/playselapsed"
    };

    [self performApiCallForMethod:@"auth.getSessionInfo"
                       withParams:@{}
                        rootXpath:@"./application"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getInfoForUserOrNil:(NSString *)username successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @"./realname",
        @"username": @"./name",
        @"gender": @"./gender",
        @"age": @"./age",
        @"playcount": @"./playcount",
        @"country": @"./country",
        @"image": @"./image[@size=\"large\"]",
        @"url": @"./url"
    };

    NSDictionary *params = @{};
    if (username) {
        params = @{@"user": username};
    }

    [self performApiCallForMethod:@"user.getInfo"
                       withParams:params
                        rootXpath:@"./user"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)sendNowPlayingTrack:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album withDuration:(NSTimeInterval)duration successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *params = @{
        @"track": track,
        @"artist": artist,
        @"album": album,
        @"duration": @(duration)
    };

    [self performApiCallForMethod:@"track.updateNowPlaying"
                       withParams:params
                        rootXpath:@"."
                 returnDictionary:YES
                    mappingObject:@{}
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)sendScrobbledTrack:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album withDuration:(NSTimeInterval)duration atTimestamp:(NSTimeInterval)timestamp successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *params = @{
        @"track": track,
        @"artist": artist,
        @"album": album,
        @"duration": @(duration),
        @"timestamp": @(timestamp)
    };

    [self performApiCallForMethod:@"track.scrobble"
                       withParams:params
                        rootXpath:@"."
                 returnDictionary:YES
                    mappingObject:@{}
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark Chart methods

- (void)getTopTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @"./name",
        @"playcount": @"./playcount",
        @"listeners": @"./listeners",
        @"image": @"./image[@size=\"large\"]",
        @"artist": @"./artist/name"
    };

    [self performApiCallForMethod:@"chart.getTopTracks"
                       withParams:@{@"limit": @(limit), @"page": @(page)}
                        rootXpath:@"./tracks/track"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getHypedTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @"./name",
        @"image": @"./image[@size=\"large\"]",
        @"artist": @"./artist/name",
        @"percentagechange": @"./percentagechange"
    };

    [self performApiCallForMethod:@"chart.getHypedTracks"
                       withParams:@{@"limit": @(limit), @"page": @(page)}
                        rootXpath:@"./tracks/track"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

@end
