//
//  LastFm.m
//  lastfmlocalplayback
//
//  Created by Kevin Renskers on 17-08-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
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
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
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
        self.numberFormatter = [[NSNumberFormatter alloc] init];
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        [self.dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss"];
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
        NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
            NULL,
            (__bridge CFStringRef)unencodedString,
            NULL,
            (CFStringRef)@"!*'();:@&=+$,/?%#[]", 
            kCFStringEncodingUTF8
        );
        return s;
    }
    return unencodedString;
}

- (id)transformValue:(id)value intoClass:(NSString *)targetClass {
    if ([value isKindOfClass:NSClassFromString(targetClass)]) {
        return value;
    }

    if ([targetClass isEqualToString:@"NSNumber"]) {
        if ([value isKindOfClass:[NSString class]] && [value length]) {
            return [self.numberFormatter numberFromString:value];
        }
        return @0;
    }

    if ([targetClass isEqualToString:@"NSURL"]) {
        if ([value isKindOfClass:[NSString class]] && [value length]) {
            return [NSURL URLWithString:value];
        }
        return nil;
    }

    if ([targetClass isEqualToString:@"NSDate"]) {
        return [self.dateFormatter dateFromString:value];
    }

    if ([targetClass isEqualToString:@"NSArray"]) {
        if ([value isKindOfClass:[NSString class]] && [value length]) {
            return [NSArray arrayWithObject:value];
        }
        return [NSArray array];
    }

    NSLog(@"Invalid targetClass (%@)", targetClass);
    return value;
}

- (NSString *)forceString:(NSString *)value {
    if (!value) return @"";
    return value;
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

        if (self.username && ![params objectForKey:@"username"]) {
            [newParams setObject:self.username forKey:@"username"];
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
            [sortedParamsArray addObject:[NSString stringWithFormat:@"%@=%@", [self urlEscapeString:key], [self urlEscapeString:[newParams objectForKey:key]]]];
        }

        // Do we need to POST or GET?
        BOOL doPost = YES;
        NSArray *methodParts = [method componentsSeparatedByString:@"."];
        if ([methodParts count] > 1) {
            NSString *secondPart = [methodParts objectAtIndex:1];
            if ([secondPart hasPrefix:@"get"]) {
                doPost = NO;
            }
        }

        NSMutableURLRequest *request;
        if (doPost) {
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:API_URL]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[[NSString stringWithFormat:@"%@&api_sig=%@", [sortedParamsArray componentsJoinedByString:@"&"], [self md5sumFromString:signature]] dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            NSString *paramsString = [NSString stringWithFormat:@"%@&api_sig=%@", [sortedParamsArray componentsJoinedByString:@"&"], [self md5sumFromString:signature]];
            NSString *urlString = [NSString stringWithFormat:@"%@?%@", API_URL, paramsString];
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        }

        NSURLResponse *response;
        NSError *error;

        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

        // Check for NSURLConnection errors
        if (error) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failureHandler(error);
                }];
            }
            return;
        }

        DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];

        // Check for XML parsing errors
        if (error) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failureHandler(error);
                }];
            }
            return;
        }

        // Check for Last.fm errors
        if (![[[document rootElement] objectAtXPath:@"./@status"] isEqualToString:@"ok"]) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSError *lastfmError = [[NSError alloc] initWithDomain:LastFmServiceErrorDomain
                                                                      code:[[[document rootElement] objectAtXPath:@"./error/@code"] intValue]
                                                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[[document rootElement] objectAtXPath:@"./error"], NSLocalizedDescriptionKey, method, @"method", nil]];

                    failureHandler(lastfmError);
                }];
            }
            return;
        }

        NSArray *output = [[document rootElement] nodesForXPath:rootXpath error:&error];
        NSMutableArray *returnArray = [NSMutableArray array];

        for (DDXMLNode *node in output) {
            // Convert this node to a dictionary using the mapping object (keys and xpaths)
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            [result setObject:newParams forKey:@"_params"];

            for (NSString *key in mappingObject) {
                NSArray *mappingArray = [mappingObject objectForKey:key];
                NSString *xpath = [mappingArray objectAtIndex:0];
                NSString *targetClass = [mappingArray objectAtIndex:1];
                NSString *value = [node objectAtXPath:xpath];
                id correctValue = [self transformValue:value intoClass:targetClass];
                if (correctValue != nil) {
                    [result setObject:correctValue forKey:key];
                }
            }

            [returnArray addObject:result];
        }

        if (returnArray && returnArray.count) {
            if (successHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (returnDictionary) {
                        successHandler([returnArray objectAtIndex:0]);
                    } else {
                        successHandler(returnArray);
                    }
                }];
            }
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

- (void)getInfoForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"bio": @[ @"./bio/content", @"NSString" ],
        @"summary": @[ @"./bio/summary", @"NSString" ],
        @"name": @[ @"./name", @"NSString" ],
        @"url": @[ @"./url", @"NSURL" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ],
        @"listeners": @[ @"./stats/listeners", @"NSNumber" ],
        @"playcount": @[ @"./stats/playcount", @"NSNumber" ],
        @"userplaycount": @[ @"./stats/userplaycount", @"NSNumber" ],
        @"tags": @[ @"./tags/tag/name", @"NSArray" ]
    };

    [self performApiCallForMethod:@"artist.getInfo"
                       withParams:@{ @"artist": [self forceString:artist] }
                        rootXpath:@"./artist"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getEventsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"title": @[ @"./title", @"NSString" ],
        @"headliner": @[ @"./artists/headliner", @"NSString" ],
        @"attendance": @[ @"./attendance", @"NSNumber" ],
        @"description": @[ @"./description", @"NSString" ],
        @"startDate": @[ @"./startDate", @"NSDate" ],
        @"url": @[ @"./url", @"NSURL" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ],
        @"venue": @[ @"./venue/name", @"NSString" ],
        @"city": @[ @"./venue/location/city", @"NSString" ],
        @"country": @[ @"./venue/location/country", @"NSString" ],
        @"venue_url": @[ @"./venue/website", @"NSURL" ]
    };

    [self performApiCallForMethod:@"artist.getEvents"
                       withParams:@{ @"artist": [self forceString:artist] }
                        rootXpath:@"./events/event"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getTopAlbumsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"artist": @[ @"./artist/name", @"NSString" ],
        @"title": @[ @"./name", @"NSString" ],
        @"playcount": @[ @"./playcount", @"NSNumber" ],
        @"url": @[ @"./url", @"NSURL" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ]
    };

    [self performApiCallForMethod:@"artist.getTopAlbums"
                       withParams:@{ @"artist": [self forceString:artist], @"limit": @"500" }
                        rootXpath:@"./topalbums/album"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getTopTracksForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"playcount": @[ @"./playcount", @"NSNumber" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ]
    };

    [self performApiCallForMethod:@"artist.getTopTracks"
                       withParams:@{ @"artist": [self forceString:artist], @"limit": @"500" }
                        rootXpath:@"./toptracks/track"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getImagesForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"format": @[ @"format", @"NSString"],
        @"original": @[ @"./sizes/size[@name=\"original\"]", @"NSURL" ],
        @"extralarge": @[ @"./sizes/size[@name=\"extralarge\"]", @"NSURL" ],
        @"large": @[ @"./sizes/size[@name=\"large\"]", @"NSURL" ],
        @"largesquare": @[ @"./sizes/size[@name=\"largesquare\"]", @"NSURL" ],
        @"medium": @[ @"./sizes/size[@name=\"medium\"]", @"NSURL" ],
        @"small": @[ @"./sizes/size[@name=\"small\"]", @"NSURL" ],
        @"title": @[ @"title", @"NSString" ],
        @"url": @[ @"url", @"NSURL" ],
        @"tags": @[ @"./tags/tag/name", @"NSArray" ],
        @"owner": @[ @"./owner/name", @"NSString" ]
    };

    [self performApiCallForMethod:@"artist.getImages"
                       withParams:@{ @"artist": [self forceString:artist], @"limit": @"500" }
                        rootXpath:@"./images/image"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];

}

- (void)getSimilarArtistsTo:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"match": @[ @"./match", @"NSNumber" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ]
    };

    [self performApiCallForMethod:@"artist.getSimilar"
                       withParams:@{ @"artist": [self forceString:artist], @"limit": @"500" }
                        rootXpath:@"./similarartists/artist"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark Album methods

- (void)getInfoForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"artist": @[ @"./artist", @"NSString" ],
        @"name": @[ @"./name", @"NSString" ],
        @"listeners": @[ @"./listeners", @"NSNumber" ],
        @"playcount": @[ @"./playcount", @"NSNumber" ],
        @"url": @[ @"./url", @"NSURL" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ],
        @"releasedate": @[ @"./releasedate", @"NSString" ],
        @"tags": @[ @"./toptags/tag/name", @"NSArray" ],
        @"userplaycount": @[ @"./userplaycount", @"NSNumber" ]
    };

    [self performApiCallForMethod:@"album.getInfo"
                       withParams:@{ @"artist": [self forceString:artist], @"album": [self forceString:album] }
                        rootXpath:@"./album"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getTracksForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"rank": @[ @"@rank", @"NSNumber" ],
        @"artist": @[ @"./artist/name", @"NSString" ],
        @"name": @[ @"./name", @"NSString" ],
        @"duration": @[ @"./duration", @"NSNumber" ],
        @"url": @[ @"./url", @"NSURL" ]
    };

    [self performApiCallForMethod:@"album.getInfo"
                       withParams:@{ @"artist": [self forceString:artist], @"album": [self forceString:album] }
                        rootXpath:@"./album/tracks/track"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getBuyLinksForAlbum:(NSString *)album artist:(NSString *)artist country:(NSString *)country successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"url": @[ @"./buyLink", @"NSURL" ],
        @"price": @[ @"./price/amount", @"NSNumber" ],
        @"currency": @[ @"./price/currency", @"NSString" ],
        @"name": @[ @"./supplierName", @"NSString" ],
        @"icon": @[ @"./supplierIcon", @"NSURL" ]
    };

    [self performApiCallForMethod:@"album.getBuylinks"
                       withParams:@{ @"artist": [self forceString:artist], @"album": [self forceString:album], @"country": [self forceString:country] }
                        rootXpath:@"./affiliations/downloads/affiliation"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getTopTagsForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"count": @[ @"./count", @"NSNumber" ],
        @"url": @[ @"./url", @"NSString" ]
    };

    [self performApiCallForMethod:@"album.getTopTags"
                       withParams:@{ @"artist": [self forceString:artist], @"album": [self forceString:album] }
                        rootXpath:@"./toptags/tag"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark Track methods

- (void)getInfoForTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"listeners": @[ @"./listeners", @"NSNumber" ],
        @"playcount": @[ @"./playcount", @"NSNumber" ],
        @"tags": @[ @"./toptags/tag/name", @"NSArray" ],
        @"artist": @[ @"./artist/name", @"NSString" ],
        @"album": @[ @"./album/title", @"NSString" ],
        @"image": @[ @"./album/image[@size=\"large\"]", @"NSURL" ],
        @"wiki": @[ @"./wiki/summary", @"NSString" ],
        @"duration": @[ @"./duration", @"NSNumber" ],
        @"userplaycount": @[ @"./userplaycount", @"NSNumber" ],
        @"userloved": @[ @"./userloved", @"NSNumber" ]
    };

    [self performApiCallForMethod:@"track.getInfo"
                       withParams:@{ @"track": [self forceString:title], @"artist": [self forceString:artist] }
                        rootXpath:@"./track"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getInfoForTrack:(NSString *)musicBrainId successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"listeners": @[ @"./listeners", @"NSNumber" ],
        @"playcount": @[ @"./playcount", @"NSNumber" ],
        @"tags": @[ @"./toptags/tag/name", @"NSArray" ],
        @"artist": @[ @"./artist/name", @"NSString" ],
        @"album": @[ @"./album/title", @"NSString" ],
        @"image": @[ @"./album/image[@size=\"large\"]", @"NSURL" ],
        @"wiki": @[ @"./wiki/summary", @"NSString" ],
        @"duration": @[ @"./duration", @"NSNumber" ],
        @"userplaycount": @[ @"./userplaycount", @"NSNumber" ],
        @"userloved": @[ @"./userloved", @"NSNumber" ]
    };

    [self performApiCallForMethod:@"track.getInfo"
                       withParams:@{ @"mbid": [self forceString:musicBrainId] }
                        rootXpath:@"./track"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)loveTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    [self performApiCallForMethod:@"track.love"
                       withParams:@{ @"track": [self forceString:title], @"artist": [self forceString:artist] }
                        rootXpath:@"."
                 returnDictionary:YES
                    mappingObject:@{}
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)unloveTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    [self performApiCallForMethod:@"track.unlove"
                       withParams:@{ @"track": [self forceString:title], @"artist": [self forceString:artist] }
                        rootXpath:@"."
                 returnDictionary:YES
                    mappingObject:@{}
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)banTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    [self performApiCallForMethod:@"track.ban"
                       withParams:@{ @"track": [self forceString:title], @"artist": [self forceString:artist] }
                        rootXpath:@"."
                 returnDictionary:YES
                    mappingObject:@{}
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)unbanTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    [self performApiCallForMethod:@"track.unban"
                       withParams:@{ @"track": [self forceString:title], @"artist": [self forceString:artist] }
                        rootXpath:@"."
                 returnDictionary:YES
                    mappingObject:@{}
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getBuyLinksForTrack:(NSString *)title artist:(NSString *)artist country:(NSString *)country successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"url": @[ @"./buyLink", @"NSURL" ],
        @"price": @[ @"./price/amount", @"NSNumber" ],
        @"currency": @[ @"./price/currency", @"NSString" ],
        @"name": @[ @"./supplierName", @"NSString" ],
        @"icon": @[ @"./supplierIcon", @"NSURL" ]
    };

    [self performApiCallForMethod:@"track.getBuylinks"
                       withParams:@{ @"track": [self forceString:title], @"artist": [self forceString:artist], @"country": [self forceString:country] }
                        rootXpath:@"./affiliations/downloads/affiliation"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark User methods

- (void)getSessionForUser:(NSString *)username password:(NSString *)password successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    username = [self forceString:username];
    password = [self forceString:password];
    NSString *authToken = [self md5sumFromString:[NSString stringWithFormat:@"%@%@", [username lowercaseString], [self md5sumFromString:password]]];

    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"key": @[ @"./key", @"NSString" ],
        @"subscriber": @[ @"./subscriber", @"NSNumber" ]
    };

    [self performApiCallForMethod:@"auth.getMobileSession"
                       withParams:@{ @"username": [username lowercaseString], @"authToken": authToken }
                        rootXpath:@"./session"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getSessionInfoWithSuccessHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./session/name", @"NSString" ],
        @"subscriber": @[ @"./session/subscriber", @"NSNumber" ],
        @"country": @[ @"./country", @"NSString" ],
        @"radio_enabled": @[ @"./radioPermission/user[@type=\"you\"]/radio", @"NSNumber" ],
        @"trial_enabled": @[ @"./radioPermission/user[@type=\"you\"]/freetrial", @"NSNumber" ],
        @"trial_expired": @[ @"./radioPermission/user[@type=\"you\"]/trial/expired", @"NSNumber" ],
        @"trial_playsleft": @[ @"./radioPermission/user[@type=\"you\"]/trial/playsleft", @"NSNumber" ],
        @"trial_playselapsed": @[ @"./radioPermission/user[@type=\"you\"]/trial/playselapsed", @"NSNumber" ]
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
        @"name": @[ @"./realname", @"NSString" ],
        @"username": @[ @"./name", @"NSString" ],
        @"gender": @[ @"./gender", @"NSString" ],
        @"age": @[ @"./age", @"NSNumber" ],
        @"playcount": @[ @"./playcount", @"NSNumber" ],
        @"country": @[ @"./country", @"NSString" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ],
        @"url": @[ @"./url", @"NSURL" ]
    };

    NSDictionary *params = @{};
    if (username) {
        params = @{ @"user": [self forceString:username] };
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
        @"track": [self forceString:track],
        @"artist": [self forceString:artist],
        @"album": [self forceString:album],
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
        @"track": [self forceString:track],
        @"artist": [self forceString:artist],
        @"album": [self forceString:album],
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

- (void)getNewReleasesForUserBasedOnRecommendations:(BOOL)basedOnRecommendations successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"artist": @[ @"./artist/name", @"NSString" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ],
        @"releasedate": @[ @"@releasedate", @"NSString" ]
    };

    NSDictionary *params = @{
        @"user": [self forceString:[self username]],
        @"userec": @(basedOnRecommendations)
    };

    [self performApiCallForMethod:@"user.getNewReleases"
                       withParams:params
                        rootXpath:@"./albums/album"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getRecommendedAlbumsWithLimit:(NSInteger)limit successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"artist": @[ @"./artist/name", @"NSString" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ]
    };

    [self performApiCallForMethod:@"user.getRecommendedAlbums"
                       withParams:@{ @"limit": @(limit) }
                        rootXpath:@"./recommendations/album"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)logout {
    self.session = nil;
    self.username = nil;
}

#pragma mark Chart methods

- (void)getTopTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"playcount": @[ @"./playcount", @"NSNumber" ],
        @"listeners": @[ @"./listeners", @"NSNumber" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ],
        @"artist": @[ @"./artist/name", @"NSString" ]
    };

    [self performApiCallForMethod:@"chart.getTopTracks"
                       withParams:@{ @"limit": @(limit), @"page": @(page) }
                        rootXpath:@"./tracks/track"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getHypedTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
        @"name": @[ @"./name", @"NSString" ],
        @"image": @[ @"./image[@size=\"large\"]", @"NSURL" ],
        @"artist": @[ @"./artist/name", @"NSString" ],
        @"percentagechange": @[ @"./percentagechange", @"NSNumber" ]
    };

    [self performApiCallForMethod:@"chart.getHypedTracks"
                       withParams:@{ @"limit": @(limit), @"page": @(page) }
                        rootXpath:@"./tracks/track"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

@end
