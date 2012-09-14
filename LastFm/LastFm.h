//
//  LastFm.h
//  lastfmlocalplayback
//
//  Created by Kevin Renskers on 17-08-12.
//  Copyright (c) 2012 Last.fm. All rights reserved.
//

#import <Foundation/Foundation.h>

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

typedef void (^LastFmReturnBlockWithDictionary)(NSDictionary *result);
typedef void (^LastFmReturnBlockWithArray)(NSArray *result);
typedef void (^LastFmReturnBlockWithError)(NSError *error);

@interface LastFm : NSObject

@property (strong, nonatomic) NSString *session;
@property (strong, nonatomic) NSString *apiKey;
@property (strong, nonatomic) NSString *apiSecret;

+ (LastFm *)sharedInstance;

#pragma mark Artist methods

- (void)getInfoForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getEventsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getTopAlbumsForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getTopTracksForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getImagesForArtist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getImagesForArtist:(NSString *)artist fromUserOrNil:(NSString *)user successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getSimilarArtistsTo:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark Album methods

- (void)getInfoForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getTracksForAlbum:(NSString *)album artist:(NSString *)artist successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark Track methods

- (void)getInfoForTrack:(NSString *)title artist:(NSString *)artist successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getInfoForTrack:(NSString *)title artist:(NSString *)artist fromUserOrNil:(NSString*)user successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getInfoForTrack:(NSString *)musicBrainId fromUserOrNil:(NSString *)user successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark User methods

- (void)getSessionForUser:(NSString *)username password:(NSString *)password successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getSessionInfoWithSuccessHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getInfoForUserOrNil:(NSString *)username successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)sendNowPlayingTrack:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album withDuration:(NSTimeInterval)duration successHandler:(LastFmReturnBlockWithDictionary)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

#pragma mark Chart methods

- (void)getTopTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;
- (void)getHypedTracksWithLimit:(NSInteger)limit page:(NSInteger)page successHandler:(LastFmReturnBlockWithArray)successHandler failureHandler:(LastFmReturnBlockWithError)failureHandler;

@end
