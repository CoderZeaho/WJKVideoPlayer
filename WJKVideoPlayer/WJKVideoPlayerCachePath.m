//
//  WJKVideoPlayerCachePath.m
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "WJKVideoPlayerCachePath.h"
#import "WJKVideoPlayerCache.h"

NSString * const WJKVideoPlayerCacheVideoPathForTemporaryFile = @"/TemporaryFile";
NSString * const WJKVideoPlayerCacheVideoPathForFullFile = @"/FullFile";

static NSString * const kWJKVideoPlayerCacheVideoPathDomain = @"/com.wjkvideoplayer.www";
static NSString * const kWJKVideoPlayerCacheVideoFileExtension = @".mp4";
static NSString * const kWJKVideoPlayerCacheVideoIndexFileExtension = @".index";
static NSString * const kWJKVideoPlayerCacheVideoPlaybackRecordFileExtension = @".record";
@implementation WJKVideoPlayerCachePath

#pragma mark - Public

+ (NSString *)videoCachePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject
            stringByAppendingPathComponent:kWJKVideoPlayerCacheVideoPathDomain];
    if (![fileManager fileExistsAtPath:path]){
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

+ (NSString *)videoCachePathForKey:(NSString *)key {
    NSParameterAssert(key);
    if (!key) {
        return nil;
    }
    NSString *videoCachePath = [self videoCachePath];
    NSParameterAssert(videoCachePath);
    NSString *filePath = [videoCachePath stringByAppendingPathComponent:[WJKVideoPlayerCache.sharedCache cacheFileNameForKey:key]];
    NSParameterAssert(filePath);
    return filePath;
}

+ (NSString *)createVideoFileIfNeedThenFetchItForKey:(NSString *)key {
    NSString *filePath = [self videoCachePathForKey:key];
    if(!filePath){
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    return filePath;
}

+ (NSString *)videoCacheIndexFilePathForKey:(NSString *)key {
    NSParameterAssert(key);
    if (!key) {
        return nil;
    }
    NSString *videoCachePath = [self videoCachePath];
    NSParameterAssert(videoCachePath);
    NSString *filePath = [videoCachePath stringByAppendingPathComponent:[WJKVideoPlayerCache.sharedCache cacheFileNameForKey:key]];
    filePath = [filePath stringByAppendingString:kWJKVideoPlayerCacheVideoIndexFileExtension];
    NSParameterAssert(filePath);
    return filePath;
}

+ (NSString *)createVideoIndexFileIfNeedThenFetchItForKey:(NSString *)key {
    NSString *filePath = [self videoCacheIndexFilePathForKey:key];
    if(!filePath){
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    return filePath;
}

+ (NSString *)videoPlaybackRecordFilePath {
    NSString *filePath = [self videoCachePath];
    if(!filePath){
        return nil;
    }
    filePath = [filePath stringByAppendingPathComponent:kWJKVideoPlayerCacheVideoPlaybackRecordFileExtension];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    return filePath;
}

@end

@implementation WJKVideoPlayerCachePath(Deprecated)

+ (NSString *)videoCacheTemporaryPathForKey:(NSString * _Nonnull)key{
    NSParameterAssert(key);
    if (!key) {
        return nil;
    }

    NSString *path = [self getFilePathWithAppendingString:WJKVideoPlayerCacheVideoPathForTemporaryFile];
    path = [path stringByAppendingPathComponent:[WJKVideoPlayerCache.sharedCache cacheFileNameForKey:key]];
    path = [path stringByAppendingString:kWJKVideoPlayerCacheVideoFileExtension];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createFileAtPath:path contents:nil attributes:nil];
    }
    return path;
}

+ (NSString *)videoCacheFullPathForKey:(NSString * _Nonnull)key{
    NSParameterAssert(key);
    if (!key) {
        return nil;
    }

    NSString *path = [self getFilePathWithAppendingString:WJKVideoPlayerCacheVideoPathForFullFile];
    NSString *fileName = [[WJKVideoPlayerCache.sharedCache cacheFileNameForKey:key]
            stringByAppendingString:kWJKVideoPlayerCacheVideoFileExtension];
    path = [path stringByAppendingPathComponent:fileName];
    return path;
}

+ (NSString *)videoCachePathForAllTemporaryFile{
    return [self getFilePathWithAppendingString:WJKVideoPlayerCacheVideoPathForTemporaryFile];
}

+ (NSString *)videoCachePathForAllFullFile{
    return [self getFilePathWithAppendingString:WJKVideoPlayerCacheVideoPathForFullFile];
}

+ (NSString *)getFilePathWithAppendingString:(nonnull NSString *)apdStr{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject
            stringByAppendingPathComponent:apdStr];
    if (![fileManager fileExistsAtPath:path]){
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

@end
