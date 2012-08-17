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


@implementation LastFm

+ (LastFm *)sharedInstance {
    static dispatch_once_t pred;
    static LastFm *sharedInstance = nil;
    dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
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

- (NSString*)urlEscapeString:(NSString *)unencodedString {
    CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
    NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
    CFRelease(originalStringRef);
    return s;
}

- (void)performApiCallForMethod:(NSString*)method
                     withParams:(NSDictionary *)params
                      rootXpath:(NSString *)rootXpath
               returnDictionary:(BOOL)returnDictionary
                  mappingObject:(NSDictionary *)mappingObject
                 successHandler:(LastFmReturnBlockWithObject)successHandler
                 failureHandler:(LastFmReturnBlockWithError)failureHandler {

    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(concurrentQueue, ^{
        NSMutableDictionary *newParams = [params mutableCopy];
        [newParams setObject:method forKey:@"method"];
        [newParams setObject:self.api_key forKey:@"api_key"];

        if (self.session) {
            [newParams setObject:self.session forKey:@"sk"];
        }

        // Create signature. This is annoying, we need to sort all the params
        NSArray *sortedParamKeys = [[newParams allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSMutableString *signature = [[NSMutableString alloc] init];
        for (NSString *key in sortedParamKeys) {
            [signature appendString:[NSString stringWithFormat:@"%@%@", key, [newParams objectForKey:key]]];
        }
        [signature appendString:self.api_secret];

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
            dispatch_async(dispatch_get_main_queue(), ^{
                failureHandler(error);
            });
            return;
        }

        DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];

        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureHandler(error);
            });
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

            [returnArray addObject:result];
        }

        if (returnArray && returnArray.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (returnDictionary) {
                    successHandler([returnArray objectAtIndex:0]);
                } else {
                    successHandler(returnArray);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureHandler(error);
            });
        }
    });
}

#pragma mark -
#pragma mark Artist methods

- (void)getInfoForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
    @"bio": @"./bio/content",
    @"summary": @"./bio/summary",
    @"name": @"./name",
    @"listeners": @"./stats/listeners",
    @"playcount": @"./stats/playcount",
    @"url": @"./url",
    @"images": @"./image"
    };

    [self performApiCallForMethod:@"artist.getInfo"
                       withParams:@{@"artist": artist}
                        rootXpath:@"./artist"
                 returnDictionary:YES
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getEventsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
    @"headliner": @"./artists/headliner",
    @"attendance": @"./attendance",
    @"description": @"./description",
    @"startDate": @"./startDate",
    @"url": @"./url",
    @"images": @"./image"
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
    @"images": @"./image"
    };

    [self performApiCallForMethod:@"artist.getTopAlbums"
                       withParams:@{@"artist": artist, @"limit": @"500"}
                        rootXpath:@"./topalbums/album"
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
    @"utl": @"url"
    };

    [self performApiCallForMethod:@"artist.getImages"
                       withParams:@{@"artist": artist, @"limit": @"500"}
                        rootXpath:@"./images/image"
                 returnDictionary:NO
                    mappingObject:mappingObject
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark Album methods

- (void)getInfoForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler {
    NSDictionary *mappingObject = @{
    @"artist": @"./artist",
    @"name": @"./name",
    @"listeners": @"./listeners",
    @"playcount": @"./playcount",
    @"url": @"./url",
    @"images": @"./image",
    @"releasedate": @"./releasedate"
    };

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

@end
