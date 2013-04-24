//
//  LastFm.h
//  lastfmlocalplayback
//
//  Created by Kevin Renskers on 17-08-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LastFmServiceErrorDomain @"LastFmServiceErrorDomain"

enum LastFmServiceErrorCodes {
	kLastFmErrorCodeInvalidService = 2,
	kLastFmErrorCodeInvalidMethod = 3,
	kLastFmErrorCodeAuthenticationFailed = 4,
	kLastFmErrorCodeInvalidFormat = 5,
	kLastFmErrorCodeInvalidParameters = 6,
	kLastFmErrorCodeInvalidResource = 7,
	kLastFmErrorCodeOperationFailed = 8,
	kLastFmErrorCodeInvalidSession = 9,
	kLastFmErrorCodeInvalidAPIKey = 10,
	kLastFmErrorCodeServiceOffline = 11,
	kLastFmErrorCodeSubscribersOnly = 12,
	kLastFmErrorCodeInvalidAPISignature = 13
};

enum LastFmRadioErrorCodes {
	kLastFmErrorCodeTrialExpired = 18,
	kLastFmErrorCodeNotEnoughContent = 20,
	kLastFmErrorCodeNotEnoughMembers = 21,
	kLastFmErrorCodeNotEnoughFans = 22,
	kLastFmErrorCodeNotEnoughNeighbours = 23,
	kLastFmErrorCodeDeprecated = 27,
	kLastFmErrorCodeGeoRestricted = 28
};

typedef enum {
	kLastFmPeriodOverall,
    kLastFmPeriodWeek,
    kLastFmPeriodMonth,
    kLastFmPeriodQuarter,
    kLastFmPeriodHalfYear,
    kLastFmPeriodYear,
} LastFmPeriod;

typedef void (^LastFmReturnBlockWithObject)(id result);
typedef void (^LastFmReturnBlockWithDictionary)(NSDictionary *result);
typedef void (^LastFmReturnBlockWithArray)(NSArray *result);
typedef void (^LastFmReturnBlockWithError)(NSError *error);

@protocol LastFmCache <NSObject>
@optional
- (NSArray *)cachedArrayForKey:(NSString *)key;
- (NSArray *)cachedArrayForKey:(NSString *)key requestParams:(NSDictionary *)params;
- (BOOL)cacheExpiredForKey:(NSString *)key;
- (BOOL)cacheExpiredForKey:(NSString *)key requestParams:(NSDictionary *)params;
- (void)cacheArray:(NSArray *)array forKey:(NSString *)key maxAge:(NSTimeInterval)maxAge;
- (void)cacheArray:(NSArray *)array requestParams:(NSDictionary *)params forKey:(NSString *)key maxAge:(NSTimeInterval)maxAge;
@end

@interface LastFm : NSObject

@property (strong, nonatomic) NSString *session;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *apiKey;
@property (strong, nonatomic) NSString *apiSecret;
@property (unsafe_unretained, nonatomic) id <LastFmCache> cacheDelegate;
@property (nonatomic) NSInteger maxConcurrentOperationCount; // default: 4
@property (nonatomic) NSTimeInterval timeoutInterval;        // default: 10

+ (LastFm *)sharedInstance;
- (NSString *)forceString:(NSString *)value;
- (NSOperation *)performApiCallForMethod:(NSString*)method withParams:(NSDictionary *)params rootXpath:(NSString *)rootXpath returnDictionary:(BOOL)returnDictionary mappingObject:(NSDictionary *)mappingObject successHandler:(LastFmReturnBlockWithObject)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)performApiCallForMethod:(NSString*)method useCache:(BOOL)useCache withParams:(NSDictionary *)params rootXpath:(NSString *)rootXpath returnDictionary:(BOOL)returnDictionary mappingObject:(NSDictionary *)mappingObject successHandler:(LastFmReturnBlockWithObject)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark Artist methods

- (NSOperation *)getInfoForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getEventsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getTopAlbumsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getTopTracksForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getImagesForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getSimilarArtistsTo:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getTopArtistsForUserOrNil:(NSString *)username period:(LastFmPeriod)period limit:(NSInteger)limit successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark Album methods

- (NSOperation *)getInfoForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getTracksForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getBuyLinksForAlbum:(NSString *)album artist:(NSString *)artist country:(NSString *)country successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getTopTagsForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark Track methods

- (NSOperation *)getInfoForTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getInfoForTrack:(NSString *)musicBrainId successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)loveTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)unloveTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)banTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)unbanTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getBuyLinksForTrack:(NSString *)title artist:(NSString *)artist country:(NSString *)country successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getRecentTracksForUserOrNil:(NSString *)username limit:(NSInteger)limit successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getLovedTracksForUserOrNil:(NSString *)username limit:(NSInteger)limit successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getTopTracksForUserOrNil:(NSString *)username period:(LastFmPeriod)period limit:(NSInteger)limit successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark User methods

- (NSOperation *)createUserWithUsername:(NSString *)username password:(NSString *)password email:(NSString *)email successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getSessionForUser:(NSString *)username password:(NSString *)password successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getSessionInfoWithSuccessHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getInfoForUserOrNil:(NSString *)username successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)sendNowPlayingTrack:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album withDuration:(NSTimeInterval)duration successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)sendScrobbledTrack:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album withDuration:(NSTimeInterval)duration atTimestamp:(NSTimeInterval)timestamp successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getNewReleasesForUserBasedOnRecommendations:(BOOL)basedOnRecommendations successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getRecommendedAlbumsWithLimit:(NSInteger)limit successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)logout;

#pragma mark Chart methods

- (NSOperation *)getTopTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (NSOperation *)getHypedTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

@end
