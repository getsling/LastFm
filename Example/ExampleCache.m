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
    return [self.cache objectForKey:key];
}

- (void)cacheArray:(NSArray *)array forKey:(NSString *)key {
    [self.cache setObject:array forKey:key];
}

@end
