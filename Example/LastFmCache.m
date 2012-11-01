//
//  ExampleCache.m
//  Example
//
//  Created by Kevin Renskers on 31-10-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "LastFmCache.h"

@interface LastFmCache ()
@property (strong, nonatomic) NSCache *cache;
@end

@implementation LastFmCache

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

- (NSArray *)cachedArrayForKey:(NSString *)key {
    return [self.cache objectForKey:key];
}

- (void)cacheArray:(NSArray *)array forKey:(NSString *)key maxAge:(NSTimeInterval)maxAge {
    [self.cache setObject:array forKey:key];
}

@end


/*
 * Better example: uses memory cache but falls back to disk cache
 * with the help of EGOCache.
 *

#import "LastFmCache.h"
#import "EGOCache.h"

@interface LastFmCache ()
@property (strong, nonatomic) NSCache *cache;
@end

@implementation LastFmCache

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

- (NSArray *)cachedArrayForKey:(NSString *)key {
    // Get from memory
    NSArray *result = [self.cache objectForKey:key];
    if (result) {
        DLog(@"Memory cache hit");
        return result;
    }

    // Get from disk
    NSData *data = [[EGOCache currentCache] dataForKey:key];
    if (data) {
        DLog(@"Disk cache hit");
        // Save in memory
        result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [self.cache setObject:result forKey:key];
        return result;
    }

    return nil;
}

- (void)cacheArray:(NSArray *)array forKey:(NSString *)key maxAge:(NSTimeInterval)maxAge {
    // Save in memory
    [self.cache setObject:array forKey:key];

    // Also save to disk
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
    [[EGOCache currentCache] setData:data forKey:key withTimeoutInterval:maxAge];
}

@end

*/