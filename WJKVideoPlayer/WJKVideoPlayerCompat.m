//
//  WJKVideoPlayerCompat.m
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/4/28.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "WJKVideoPlayerCompat.h"
#import <AVFoundation/AVFoundation.h>

NSString *const WJKVideoPlayerDownloadStartNotification = @"www.wjkvideplayer.download.start.notification";
NSString *const WJKVideoPlayerDownloadReceiveResponseNotification = @"www.wjkvideoplayer.download.received.response.notification";
NSString *const WJKVideoPlayerDownloadStopNotification = @"www.wjkvideplayer.download.stop.notification";
NSString *const WJKVideoPlayerDownloadFinishNotification = @"www.wjkvideplayer.download.finished.notification";
NSString *const WJKVideoPlayerErrorDomain = @"com.wjkvideoplayer.error.domain.www";
const NSRange WJKInvalidRange = {NSNotFound, 0};

void WJKDispatchSyncOnMainQueue(dispatch_block_t block) {
    if (!block) { return; }
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

BOOL WJKValidByteRange(NSRange range) {
    return ((range.location != NSNotFound) || (range.length > 0));
}

BOOL WJKValidFileRange(NSRange range) {
    return ((range.location != NSNotFound) && range.length > 0 && range.length != NSUIntegerMax);
}

BOOL WJKRangeCanMerge(NSRange range1, NSRange range2) {
    return (NSMaxRange(range1) == range2.location) || (NSMaxRange(range2) == range1.location) || NSIntersectionRange(range1, range2).length > 0;
}

NSString* WJKRangeToHTTPRangeHeader(NSRange range) {
    if (WJKValidByteRange(range)) {
        if (range.location == NSNotFound) {
            return [NSString stringWithFormat:@"bytes=-%tu",range.length];
        }
        else if (range.length == NSUIntegerMax) {
            return [NSString stringWithFormat:@"bytes=%tu-",range.location];
        }
        else {
            return [NSString stringWithFormat:@"bytes=%tu-%tu",range.location, NSMaxRange(range) - 1];
        }
    }
    else {
        return nil;
    }
}

NSError *WJKErrorWithDescription(NSString *description) {
    assert(description);
    if(!description.length){
        return nil;
    }

    return [NSError errorWithDomain:WJKVideoPlayerErrorDomain
                               code:0 userInfo:@{
                    NSLocalizedDescriptionKey : description
    }];
}
