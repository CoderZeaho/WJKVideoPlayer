//
//  WJKVideoPlayerResourceLoader.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class WJKVideoPlayerResourceLoader,
       WJKResourceLoadingRequestWebTask,
       WJKVideoPlayerCacheFile;

NS_ASSUME_NONNULL_BEGIN

@protocol WJKVideoPlayerResourceLoaderDelegate<NSObject>

@required

/**
 * This method will be called when the current instance receive new loading request.
 *
 * @prama resourceLoader     The current resource loader for videoURLAsset.
 * @prama requestTask        A abstract instance packaging the loading request.
 */
- (void)resourceLoader:(WJKVideoPlayerResourceLoader *)resourceLoader
didReceiveLoadingRequestTask:(WJKResourceLoadingRequestWebTask *)requestTask;

@end

@interface WJKVideoPlayerResourceLoader : NSObject<AVAssetResourceLoaderDelegate>

@property (nonatomic, weak) id<WJKVideoPlayerResourceLoaderDelegate> delegate;

/**
 * The url custom passed in.
 */
@property (nonatomic, strong, readonly) NSURL *customURL;

/**
 * The cache file take responsibility for save video data to disk and read cached video from disk.
 */
@property (nonatomic, strong, readonly) WJKVideoPlayerCacheFile *cacheFile;

/**
 * Convenience method to fetch instance of this class.
 *
 * @param customURL The url custom passed in.
 *
 * @return A instance of this class.
 */
+ (instancetype)resourceLoaderWithCustomURL:(NSURL *)customURL;

/**
 * Designated initializer method.
 *
 * @param customURL The url custom passed in.
 *
 * @return A instance of this class.
 */
- (instancetype)initWithCustomURL:(NSURL *)customURL NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
