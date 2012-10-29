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

typedef void (^LastFmReturnBlockWithObject)(id result);
typedef void (^LastFmReturnBlockWithDictionary)(NSDictionary *result);
typedef void (^LastFmReturnBlockWithArray)(NSArray *result);
typedef void (^LastFmReturnBlockWithError)(NSError *error);

@interface LastFm : NSObject

@property (strong, nonatomic) NSString *session;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *apiKey;
@property (strong, nonatomic) NSString *apiSecret;
@property (nonatomic) NSInteger maxConcurrentOperationCount;

+ (LastFm *)sharedInstance;
- (NSString *)forceString:(NSString *)value;
- (void)performApiCallForMethod:(NSString*)method withParams:(NSDictionary *)params rootXpath:(NSString *)rootXpath returnDictionary:(BOOL)returnDictionary mappingObject:(NSDictionary *)mappingObject successHandler:(LastFmReturnBlockWithObject)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark Artist methods

- (void)getInfoForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getEventsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getTopAlbumsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getTopTracksForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getImagesForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getSimilarArtistsTo:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark Album methods

- (void)getInfoForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getTracksForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getBuyLinksForAlbum:(NSString *)album artist:(NSString *)artist country:(NSString *)country successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getTopTagsForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark Track methods

- (void)getInfoForTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getInfoForTrack:(NSString *)musicBrainId successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)loveTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)unloveTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)banTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)unbanTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getBuyLinksForTrack:(NSString *)title artist:(NSString *)artist country:(NSString *)country successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark User methods

- (void)getSessionForUser:(NSString *)username password:(NSString *)password successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getSessionInfoWithSuccessHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getInfoForUserOrNil:(NSString *)username successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)sendNowPlayingTrack:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album withDuration:(NSTimeInterval)duration successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)sendScrobbledTrack:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album withDuration:(NSTimeInterval)duration atTimestamp:(NSTimeInterval)timestamp successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getNewReleasesForUserBasedOnRecommendations:(BOOL)basedOnRecommendations successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getRecommendedAlbumsWithLimit:(NSInteger)limit successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)logout;

#pragma mark Chart methods

- (void)getTopTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getHypedTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

@end
