//
//  WJKVideoPlayerCachePath.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WJKVideoPlayerCompat.h"

UIKIT_EXTERN NSString * _Nonnull const WJKVideoPlayerCacheVideoPathForTemporaryFile;
UIKIT_EXTERN NSString * _Nonnull const WJKVideoPlayerCacheVideoPathForFullFile;

NS_ASSUME_NONNULL_BEGIN

@interface WJKVideoPlayerCachePath : NSObject

/**
 *  Get the video cache path on version 3.x.
 *
 *  @return The file path.
 */
+ (NSString *)videoCachePath;

/**
 * Fetch the video cache path for given key on version 3.x.
 *
 * @param key A given key.
 *
 * @return The file path.
 */
+ (NSString *)videoCachePathForKey:(NSString *)key;

/**
 * Fetch the video cache path and create video file for given key on version 3.x.
 *
 * @param key A given key.
 *
 * @return The file path.
 */
+ (NSString *)createVideoFileIfNeedThenFetchItForKey:(NSString *)key;

/**
 * Fetch the index file path for given key on version 3.x.
 *
 * @param key A given key.
 *
 * @return The path of index file.
 */
+ (NSString *)videoCacheIndexFilePathForKey:(NSString *)key;

/**
 * Fetch the index file path and create video index file for given key on version 3.x.
 *
 * @param key A given key.
 *
 * @return The path of index file.
 */
+ (NSString *)createVideoIndexFileIfNeedThenFetchItForKey:(NSString *)key;

/**
 * Fetch the playback record file path.
 *
 * @return The path of playback record.
 */
+ (NSString *)videoPlaybackRecordFilePath;

@end


@interface WJKVideoPlayerCachePath(Deprecated)

/**
 *  Get the local video cache path for temporary video file.
 *
 *  @param key  The unique flag for the given url in this framework.
 *
 *  @return the temporary file path.
 */
+ (NSString *)videoCacheTemporaryPathForKey:(NSString *)key WJKDEPRECATED_ATTRIBUTE("`videoCacheTemporaryPathForKey:` is deprecated on 3.0.")

/**
 *  Get the local video cache path for all full video file.
 *
 *  @param key  The unique flag for the given url in this framework.
 *
 *  @return the full file path.
 */
+ (NSString *)videoCacheFullPathForKey:(NSString *)key WJKDEPRECATED_ATTRIBUTE("`videoCacheFullPathForKey:` is deprecated on 3.0.")

/**
 *  Get the local video cache path for all temporary video file on version 2.x.
 *
 *  @return the temporary file path.
 */
+ (NSString *)videoCachePathForAllTemporaryFile WJKDEPRECATED_ATTRIBUTE("`videoCachePathForAllTemporaryFile` is deprecated on 3.0.")

/**
 *  Get the local video cache path for all full video file on version 2.x.
 *
 *  @return the full file path.
 */
+ (NSString *)videoCachePathForAllFullFile WJKDEPRECATED_ATTRIBUTE("`videoCachePathForAllFullFile` is deprecated on 3.0.")

@end

NS_ASSUME_NONNULL_END
