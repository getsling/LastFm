//
//  ExampleCache.m
//  Example
//
//  Created by Kevin Renskers on 31-10-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "ExampleCache.h"

@interface ExampleCache ()
@property (strong, nonatomic) NSCache *cache;
@end

@implementation ExampleCache

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

- (NSArray *)cachedArrayForKey:(NSString *)key {
    // Extremely simple example. EGOCache would be something like this:
    // NSData *data = [[EGOCache currentCache] dataForKey:key];
    // if (data) {
    //     return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    // }
    // return nil;
    return [self.cache objectForKey:key];
}

- (void)cacheArray:(NSArray *)array forKey:(NSString *)key maxAge:(NSTimeInterval)maxAge {
    // Extremely simple example, only caches to memory.
    // EGOCache would be better:
    // NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
    // [[EGOCache currentCache] setData:data forKey:key withTimeoutInterval:maxAge];
    [self.cache setObject:array forKey:key];
}

@end
