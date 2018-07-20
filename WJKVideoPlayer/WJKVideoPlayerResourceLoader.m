//
//  WJKVideoPlayerResourceLoader.m
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "WJKVideoPlayerResourceLoader.h"
#import "WJKVideoPlayerCompat.h"
#import "WJKVideoPlayerCacheFile.h"
#import "WJKVideoPlayerCachePath.h"
#import "WJKVideoPlayerManager.h"
#import "WJKResourceLoadingRequestTask.h"
#import "WJKVideoPlayerSupportUtils.h"
#import <pthread.h>

@interface WJKVideoPlayerResourceLoader()<WJKResourceLoadingRequestTaskDelegate>

@property (nonatomic, strong)NSMutableArray<AVAssetResourceLoadingRequest *> *loadingRequests;

@property (nonatomic, strong) AVAssetResourceLoadingRequest *runningLoadingRequest;

@property (nonatomic, strong) WJKVideoPlayerCacheFile *cacheFile;

@property (nonatomic, strong) NSMutableArray<WJKResourceLoadingRequestTask *> *requestTasks;

@property (nonatomic, strong) WJKResourceLoadingRequestTask *runningRequestTask;

@property (nonatomic) pthread_mutex_t lock;

@property (nonatomic, strong) dispatch_queue_t ioQueue;

@end

@implementation WJKVideoPlayerResourceLoader

- (void)dealloc {
    if(self.runningRequestTask){
        [self.runningRequestTask cancel];
        [self removeCurrentRequestTaskAndResetAll];
    }
    self.loadingRequests = nil;
    pthread_mutex_destroy(&_lock);
}

- (instancetype)init {
    NSAssert(NO, @"Please use given initialize method.");
    return [self initWithCustomURL:[NSURL new]];
}

+ (instancetype)resourceLoaderWithCustomURL:(NSURL *)customURL {
    return [[WJKVideoPlayerResourceLoader alloc] initWithCustomURL:customURL];
}

- (instancetype)initWithCustomURL:(NSURL *)customURL {
    NSParameterAssert(customURL);
    if(!customURL){
        return nil;
    }

    self = [super init];
    if(self){
        pthread_mutexattr_t mutexattr;
        pthread_mutexattr_init(&mutexattr);
        pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_lock, &mutexattr);
        _ioQueue = dispatch_queue_create("com.Wujike.wjkvideoplayer.resource.loader.www", DISPATCH_QUEUE_SERIAL);
        _customURL = customURL;
        _loadingRequests = [@[] mutableCopy];
        NSString *key = [WJKVideoPlayerManager.sharedManager cacheKeyForURL:customURL];
        _cacheFile = [WJKVideoPlayerCacheFile cacheFileWithFilePath:[WJKVideoPlayerCachePath createVideoFileIfNeedThenFetchItForKey:key]
                                                     indexFilePath:[WJKVideoPlayerCachePath createVideoIndexFileIfNeedThenFetchItForKey:key]];
    }
    return self;
}


#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (resourceLoader && loadingRequest){
        [self.loadingRequests addObject:loadingRequest];
        WJKDebugLog(@"ResourceLoader 接收到新的请求, 当前请求数: %ld <<<<<<<<<<<<<<", self.loadingRequests.count);
        if(!self.runningLoadingRequest){
            [self findAndStartNextLoadingRequestIfNeed];
        }
    }
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader
didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    if ([self.loadingRequests containsObject:loadingRequest]) {
        if(loadingRequest == self.runningLoadingRequest){
            WJKDebugLog(@"取消了一个正在进行的请求");
            if(self.runningLoadingRequest && self.runningRequestTask){
                [self.runningRequestTask cancel];
            }
            if([self.loadingRequests containsObject:self.runningLoadingRequest]){
                [self.loadingRequests removeObject:self.runningLoadingRequest];
            }
            [self removeCurrentRequestTaskAndResetAll];
            [self findAndStartNextLoadingRequestIfNeed];
        }
        else {
            WJKDebugLog(@"取消了一个不在进行的请求");
            [self.loadingRequests removeObject:loadingRequest];
        }
    }
    else {
        WJKDebugLog(@"要取消的请求已经完成了");
    }
}


#pragma mark - WJKResourceLoadingRequestTaskDelegate

- (void)requestTask:(WJKResourceLoadingRequestTask *)requestTask
didCompleteWithError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    if (![self.requestTasks containsObject:requestTask]) {
        WJKDebugLog(@"完成的 task 不是正在进行的 task");
        return;
    }

    if (error) {
        [self finishCurrentRequestWithError:error];
    }
    else {
        [self finishCurrentRequestWithError:nil];
    }
}


#pragma mark - Finish Request

- (void)finishCurrentRequestWithError:(NSError *)error {
    if (error) {
        WJKDebugLog(@"ResourceLoader 完成一个请求 error: %@", error);
        [self.runningRequestTask.loadingRequest finishLoadingWithError:error];
        [self.loadingRequests removeObject:self.runningLoadingRequest];
        [self removeCurrentRequestTaskAndResetAll];
        [self findAndStartNextLoadingRequestIfNeed];
    }
    else {
        WJKDebugLog(@"ResourceLoader 完成一个请求, 没有错误");
        // 要所有的请求都完成了才行.
        [self.requestTasks removeObject:self.runningRequestTask];
        if(!self.requestTasks.count){ // 全部完成.
            [self.runningRequestTask.loadingRequest finishLoading];
            [self.loadingRequests removeObject:self.runningLoadingRequest];
            [self removeCurrentRequestTaskAndResetAll];
            [self findAndStartNextLoadingRequestIfNeed];
        }
        else { // 完成了一部分, 继续请求.
            [self startNextTaskIfNeed];
        }
    }
}


#pragma mark - Private

- (void)findAndStartNextLoadingRequestIfNeed {
    if(self.runningLoadingRequest || self.runningRequestTask){
        return;
    }
    if (self.loadingRequests.count == 0) {
        return;
    }

    self.runningLoadingRequest = [self.loadingRequests firstObject];
    NSRange dataRange = [self fetchRequestRangeWithRequest:self.runningLoadingRequest];
    if (dataRange.length == NSUIntegerMax) {
        dataRange.length = [self.cacheFile fileLength] - dataRange.location;
    }
    [self startCurrentRequestWithLoadingRequest:self.runningLoadingRequest
                                          range:dataRange];
}

- (void)startCurrentRequestWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
                                        range:(NSRange)dataRange {
    /// 是否已经完全缓存完成.
    BOOL isCompleted = self.cacheFile.isCompleted;
    WJKDebugLog(@"ResourceLoader 处理新的请求, 数据范围是: %@, 是否已经缓存完成: %@", NSStringFromRange(dataRange), isCompleted ? @"是" : @"否");
    if (dataRange.length == NSUIntegerMax) {
        [self addTaskWithLoadingRequest:loadingRequest
                                  range:NSMakeRange(dataRange.location, NSUIntegerMax)
                                 cached:NO];
    }
    else {
        NSUInteger start = dataRange.location;
        NSUInteger end = NSMaxRange(dataRange);
        while (start < end) {
            NSRange firstNotCachedRange = [self.cacheFile firstNotCachedRangeFromPosition:start];
            if (!WJKValidFileRange(firstNotCachedRange)) {
                [self addTaskWithLoadingRequest:loadingRequest
                                          range:dataRange
                                         cached:self.cacheFile.cachedDataBound > 0];
                start = end;
            }
            else if (firstNotCachedRange.location >= end) {
                [self addTaskWithLoadingRequest:loadingRequest
                                          range:dataRange
                                         cached:YES];
                start = end;
            }
            else if (firstNotCachedRange.location >= start) {
                if (firstNotCachedRange.location > start) {
                    [self addTaskWithLoadingRequest:loadingRequest
                                              range:NSMakeRange(start, firstNotCachedRange.location - start)
                                             cached:YES];
                }
                NSUInteger notCachedEnd = MIN(NSMaxRange(firstNotCachedRange), end);
                [self addTaskWithLoadingRequest:loadingRequest
                                          range:NSMakeRange(firstNotCachedRange.location, notCachedEnd - firstNotCachedRange.location)
                                         cached:NO];
                start = notCachedEnd;
            }
            else {
                [self addTaskWithLoadingRequest:loadingRequest
                                          range:dataRange
                                         cached:YES];
                start = end;
            }
        }
    }

    // 发起请求.
    [self startNextTaskIfNeed];
}

- (void)addTaskWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
                            range:(NSRange)range
                           cached:(BOOL)cached {
    WJKResourceLoadingRequestTask *task;
    if(cached){
        WJKDebugLog(@"ResourceLoader 创建了一个本地请求");
        task = [WJKResourceLoadingRequestLocalTask requestTaskWithLoadingRequest:loadingRequest
                                                                   requestRange:range
                                                                      cacheFile:self.cacheFile
                                                                      customURL:self.customURL
                                                                         cached:cached];
    }
    else {
        task = [WJKResourceLoadingRequestWebTask requestTaskWithLoadingRequest:loadingRequest
                                                                 requestRange:range
                                                                    cacheFile:self.cacheFile
                                                                    customURL:self.customURL
                                                                       cached:cached];
        WJKDebugLog(@"ResourceLoader 创建一个网络请求: %@", task);
        if (self.delegate && [self.delegate respondsToSelector:@selector(resourceLoader:didReceiveLoadingRequestTask:)]) {
            [self.delegate resourceLoader:self didReceiveLoadingRequestTask:(WJKResourceLoadingRequestWebTask *)task];
        }
    }
    int lock = pthread_mutex_trylock(&_lock);
    task.delegate = self;
    if (!self.requestTasks) {
        self.requestTasks = [@[] mutableCopy];
    }
    [self.requestTasks addObject:task];
    if (!lock) {
        pthread_mutex_unlock(&_lock);
    }
}

- (void)removeCurrentRequestTaskAndResetAll {
    self.runningLoadingRequest = nil;
    self.requestTasks = [@[] mutableCopy];
    self.runningRequestTask = nil;
}

- (void)startNextTaskIfNeed {
    int lock = pthread_mutex_trylock(&_lock);;
    self.runningRequestTask = self.requestTasks.firstObject;
    if ([self.runningRequestTask isKindOfClass:[WJKResourceLoadingRequestLocalTask class]]) {
        [self.runningRequestTask startOnQueue:self.ioQueue];
    }
    else {
        [self.runningRequestTask start];
    }
    if (!lock) {
        pthread_mutex_unlock(&_lock);
    }
}

- (NSRange)fetchRequestRangeWithRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSUInteger location, length;
    // data range.
    if ([loadingRequest.dataRequest respondsToSelector:@selector(requestsAllDataToEndOfResource)] && loadingRequest.dataRequest.requestsAllDataToEndOfResource) {
        location = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
        length = NSUIntegerMax;
    }
    else {
        location = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
        length = loadingRequest.dataRequest.requestedLength;
    }
    if(loadingRequest.dataRequest.currentOffset > 0){
        location = (NSUInteger)loadingRequest.dataRequest.currentOffset;
    }
    return NSMakeRange(location, length);
}

@end
