//
//  WJKVideoPlayerSupportUtils.m
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/4/28.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "WJKVideoPlayerSupportUtils.h"
#import "objc/runtime.h"
#import "WJKVideoPlayer.h"
#import "UIView+WebVideoCache.h"
#import "WJKVideoPlayerControlViews.h"
#import "WJKVideoPlayerCompat.h"
#import <MobileCoreServices/MobileCoreServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableString (WJKURLRequestFormatter)
- (void)wjk_appendCommandLineArgument:(NSString *)arg;

@end

@implementation NSMutableString (WJKURLRequestFormatter)

- (void)wjk_appendCommandLineArgument:(NSString *)arg {
    [self appendFormat:@" %@", [arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }

@end

@interface WJKURLRequestFormatter : NSObject

@end

@implementation WJKURLRequestFormatter

+ (NSString *)cURLCommandFromURLRequest:(NSURLRequest *)request {
    NSMutableString *command = [NSMutableString stringWithString:@"curl"];
    [command wjk_appendCommandLineArgument:[NSString stringWithFormat:@"-X %@", [request HTTPMethod]]];

    if ([[request HTTPBody] length] > 0) {
        NSMutableString *HTTPBodyString = [[NSMutableString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        [HTTPBodyString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, [HTTPBodyString length])];
        [HTTPBodyString replaceOccurrencesOfString:@"`" withString:@"\\`" options:0 range:NSMakeRange(0, [HTTPBodyString length])];
        [HTTPBodyString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, [HTTPBodyString length])];
        [HTTPBodyString replaceOccurrencesOfString:@"$" withString:@"\\$" options:0 range:NSMakeRange(0, [HTTPBodyString length])];
        [command wjk_appendCommandLineArgument:[NSString stringWithFormat:@"-d \"%@\"", HTTPBodyString]];
    }
    NSString *acceptEncodingHeader = [[request allHTTPHeaderFields] valueForKey:@"Accept-Encoding"];
    if ([acceptEncodingHeader rangeOfString:@"gzip"].location != NSNotFound) {
        [command wjk_appendCommandLineArgument:@"--compressed"];
    }
    if ([request URL]) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[request URL]];
        if (cookies.count) {
            NSMutableString *mutableCookieString = [NSMutableString string];
            for (NSHTTPCookie *cookie in cookies) {
                [mutableCookieString appendFormat:@"%@=%@;", cookie.name, cookie.value];
                }
            [command wjk_appendCommandLineArgument:[NSString stringWithFormat:@"--cookie \"%@\"", mutableCookieString]];
            }
        }
    for (id field in [request allHTTPHeaderFields]) {
        [command wjk_appendCommandLineArgument:[NSString stringWithFormat:@"-H %@", [NSString stringWithFormat:@"'%@: %@'", field, [[request valueForHTTPHeaderField:field] stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"]]]];
        }
    [command wjk_appendCommandLineArgument:[NSString stringWithFormat:@"\"%@\"", [[request URL] absoluteString]]];
    return [NSString stringWithString:command];
}

@end

@implementation NSURL (cURL)

- (NSString *)wjk_cURLCommand {
    NSURLRequest *request = [NSURLRequest requestWithURL:self];
    NSParameterAssert(request);
    if(!request){
        return nil;
    }
    return [WJKURLRequestFormatter cURLCommandFromURLRequest:request];
}

@end

@implementation NSFileHandle (WJKVideoPlayer)

- (BOOL)wjk_safeWriteData:(NSData *)data {
    NSInteger retry = 3;
    size_t bytesLeft = data.length;
    const void *bytes = [data bytes];
    int fileDescriptor = [self fileDescriptor];
    while (bytesLeft > 0 && retry > 0) {
        ssize_t amountSent = write(fileDescriptor, bytes + data.length - bytesLeft, bytesLeft);
        if (amountSent < 0) {
            // write failed.
            WJKErrorLog(@"Write file failed");
            break;
        }
        else {
            bytesLeft = bytesLeft - amountSent;
            if (bytesLeft > 0) {
                // not finished continue write after sleep 1 second.
                WJKWarningLog(@"Write file retry");
                sleep(1);  //probably too long, but this is quite rare.
                retry--;
            }
        }
    }
    return bytesLeft == 0;
}

@end

@implementation NSHTTPURLResponse (WJKVideoPlayer)

- (long long)wjk_fileLength {
    NSString *range = [self allHeaderFields][@"Content-Range"];
    if (range) {
        NSArray *ranges = [range componentsSeparatedByString:@"/"];
        if (ranges.count > 0) {
            NSString *lengthString = [[ranges lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            return [lengthString longLongValue];
        }
    }
    else {
        return [self expectedContentLength];
    }
    return 0;
}

- (BOOL)wjk_supportRange {
    return [self allHeaderFields][@"Content-Range"] != nil;
}

@end

@implementation AVAssetResourceLoadingRequest (WJKVideoPlayer)

- (void)wjk_fillContentInformationWithResponse:(NSHTTPURLResponse *)response {
    if (!response) {
        return;
    }

    self.response = response;
    if (!self.contentInformationRequest) {
        return;
    }

    NSString *mimeType = [response MIMEType];
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    self.contentInformationRequest.byteRangeAccessSupported = [response wjk_supportRange];
    self.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    self.contentInformationRequest.contentLength = [response wjk_fileLength];
    WJKDebugLog(@"填充了响应信息到 contentInformationRequest");
}

@end

@implementation NSURLSessionTask(WJKVideoPlayer)

- (void)setWebTask:(WJKResourceLoadingRequestWebTask *)webTask {
    id __weak __weak_object = webTask;
    id (^__weak_block)(void) = ^{
        return __weak_object;
    };
    objc_setAssociatedObject(self, @selector(webTask),   __weak_block, OBJC_ASSOCIATION_COPY);
}

- (WJKResourceLoadingRequestWebTask *)webTask {
    id (^__weak_block)(void) = objc_getAssociatedObject(self, _cmd);
    if (!__weak_block) {
        return nil;
    }
    return __weak_block();
}

@end

NSString *kWJKSwizzleErrorDomain = @"com.wjkvideoplayer.swizzle.www";
@implementation NSObject (WJKSwizzle)

+ (BOOL)wjk_swizzleMethod:(SEL)origSel withMethod:(SEL)altSel error:(NSError**)error {
    Method origMethod = class_getInstanceMethod(self, origSel);
    if (!origMethod) {
        *error = [NSError errorWithDomain:kWJKSwizzleErrorDomain code:0 userInfo:@{
                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"original method %@ not found for class %@", NSStringFromSelector(origSel), [self class]]
        }];
        return NO;
    }

    Method altMethod = class_getInstanceMethod(self, altSel);
    if (!altMethod) {
        *error = [NSError errorWithDomain:kWJKSwizzleErrorDomain code:0 userInfo:@{
                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"alternate method %@ not found for class %@", NSStringFromSelector(altSel), [self class]]
        }];
        return NO;
    }

    class_addMethod(self,
            origSel,
            class_getMethodImplementation(self, origSel),
            method_getTypeEncoding(origMethod));
    class_addMethod(self,
            altSel,
            class_getMethodImplementation(self, altSel),
            method_getTypeEncoding(altMethod));

    method_exchangeImplementations(class_getInstanceMethod(self, origSel), class_getInstanceMethod(self, altSel));
    return YES;
}

@end

@implementation WJKLog

+ (void)initialize {
    _logLevel = WJKLogLevelDebug;
}

+ (void)logWithFlag:(WJKLogLevel)logLevel
               file:(const char *)file
           function:(const char *)function
               line:(NSUInteger)line
             format:(NSString *)format, ... {
    if (logLevel > _logLevel) {
        return;
    }
    if (!format) {
        return;
    }


    va_list args;
    va_start(args, format);

    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    if (message.length) {
        NSString *flag;
        switch (logLevel) {
            case WJKLogLevelDebug:
                flag = @"DEBUG";
                break;

            case WJKLogLevelWarning:
                flag = @"Waring";
                break;

            case WJKLogLevelError:
                flag = @"Error";
                break;

            default:
                break;
        }

        NSString *threadName = [[NSThread currentThread] description];
        threadName = [threadName componentsSeparatedByString:@">"].lastObject;
        threadName = [threadName componentsSeparatedByString:@","].firstObject;
        threadName = [threadName stringByReplacingOccurrencesOfString:@"{number = " withString:@""];
        // message = [NSString stringWithFormat:@"[%@] [Thread: %@] %@ => [%@ + %ld]", flag, threadName, message, tempString, line];
        message = [NSString stringWithFormat:@"[%@] [Thread: %02ld] %@", flag, (long)[threadName integerValue], message];
        printf("%s\n", message.UTF8String);
    }
}

@end

@interface WJKApplicationStateMonitor()

@property(nonatomic, strong) NSMutableArray<NSNumber *> *applicationStateArray;

@property (nonatomic, assign) WJKApplicationState applicationState;

@end

@implementation WJKApplicationStateMonitor

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc {
    [self removeNotificationObserver];
}


#pragma mark - Setup

- (void)setup {
    [self addNotificationObserver];

    self.applicationStateArray = [NSMutableArray array];
    self.applicationState = WJKApplicationStateUnknown;
}

- (void)addNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackgroundNotification)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForegroundNotification)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActiveNotification)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActiveNotification)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)removeNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Notification

- (void)applicationWillResignActiveNotification {
    if (self.applicationStateArray.count) {
        [self.applicationStateArray removeAllObjects];
    }
    [self.applicationStateArray addObject:@(WJKApplicationStateWillResignActive)];
    [self callDelegateMethodWithApplicationState:WJKApplicationStateWillResignActive];
    self.applicationState = WJKApplicationStateWillResignActive;
    WJKDebugLog(@"WJKApplicationStateWillResignActive");
}

- (void)applicationDidEnterBackgroundNotification {
    [self.applicationStateArray addObject:@(WJKApplicationStateDidEnterBackground)];
    [self callDelegateMethodWithApplicationState:WJKApplicationStateDidEnterBackground];
    self.applicationState = WJKApplicationStateDidEnterBackground;
    WJKDebugLog(@"WJKApplicationStateDidEnterBackground");
}

- (void)applicationWillEnterForegroundNotification {
    [self.applicationStateArray addObject:@(WJKApplicationStateWillEnterForeground)];
    [self callDelegateMethodWithApplicationState:WJKApplicationStateWillEnterForeground];
    self.applicationState = WJKApplicationStateWillEnterForeground;
    WJKDebugLog(@"WJKApplicationStateWillEnterForeground");
}

- (void)applicationDidBecomeActiveNotification{
    [self callDelegateMethodWithApplicationState:WJKApplicationStateDidBecomeActive];
    self.applicationState = WJKApplicationStateDidBecomeActive;
    WJKDebugLog(@"WJKApplicationStateDidBecomeActive");

    BOOL didEnterBackground = NO;
    for (NSNumber *appStateNumber in self.applicationStateArray) {
        NSInteger appState = appStateNumber.integerValue;
        if (appState == WJKApplicationStateDidEnterBackground) {
            didEnterBackground = YES;
            break;
        }
    }
    if (!didEnterBackground) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(applicationDidBecomeActiveFromResignActive:)]) {
            [self.delegate applicationDidBecomeActiveFromResignActive:self];
        }
    }
    else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(applicationDidBecomeActiveFromBackground:)]) {
            [self.delegate applicationDidBecomeActiveFromBackground:self];
        }
    }
}

- (void)callDelegateMethodWithApplicationState:(WJKApplicationState)applicationState {
    if (self.delegate && [self.delegate respondsToSelector:@selector(applicationStateMonitor:applicationStateDidChange:)]) {
        [self.delegate applicationStateMonitor:self applicationStateDidChange:applicationState];
    }
}

@end

@interface WJKVideoPlayerTableViewHelper()

@property (nonatomic, weak) UITableViewCell *playingVideoCell;

@end

@implementation WJKVideoPlayerTableViewHelper

- (instancetype)init {
    NSAssert(NO, @"Please use given initialize method.");
    return [self initWithTableView:[UITableView new]];
};

- (instancetype)initWithTableView:(UITableView *)tableView {
    NSParameterAssert(tableView);
    if(!tableView){
        return nil;
    }

    self = [super init];
    if(self){
        _tableView = tableView;
        _tableViewVisibleFrame = CGRectZero;
    }
    return self;
}

- (void)handleCellUnreachableTypeInVisibleCellsAfterReloadData {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UITableView *tableView = self.tableView;
        for(UITableViewCell *cell in tableView.visibleCells){
            [self handleCellUnreachableTypeForCell:cell atIndexPath:[tableView indexPathForCell:cell]];
        }
    });
}

- (void)handleCellUnreachableTypeForCell:(UITableViewCell *)cell
                             atIndexPath:(NSIndexPath *)indexPath {
    UITableView *tableView = self.tableView;
    NSArray<UITableViewCell *> *visibleCells = [tableView visibleCells];
    if(!visibleCells.count){
        return;
    }

    NSUInteger unreachableCellCount = [self fetchUnreachableCellCountWithVisibleCellsCount:visibleCells.count];
    NSInteger sectionsCount = 1;
    if(tableView.dataSource && [tableView.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]){
        sectionsCount = [tableView.dataSource numberOfSectionsInTableView:tableView];
    }
    BOOL isFirstSectionInSections = YES;
    BOOL isLastSectionInSections = YES;
    if(sectionsCount > 1){
        if(indexPath.section != 0){
           isFirstSectionInSections = NO;
        }
        if(indexPath.section != (sectionsCount - 1)){
           isLastSectionInSections = NO;
        }
    }
    NSUInteger rows = [tableView numberOfRowsInSection:indexPath.section];
    if (unreachableCellCount > 0) {
        if (indexPath.row <= (unreachableCellCount - 1)) {
            if(isFirstSectionInSections){
                cell.wjk_unreachableCellType = WJKVideoPlayerUnreachableCellTypeTop;
            }
        }
        else if (indexPath.row >= (rows - unreachableCellCount)){
            if(isLastSectionInSections){
                cell.wjk_unreachableCellType = WJKVideoPlayerUnreachableCellTypeDown;
            }
        }
        else{
            cell.wjk_unreachableCellType = WJKVideoPlayerUnreachableCellTypeNone;
        }
    }
    else{
        cell.wjk_unreachableCellType = WJKVideoPlayerUnreachableCellTypeNone;
    }
}

- (void)playVideoInVisibleCellsIfNeed {
    if(self.playingVideoCell){
        [self playVideoWithCell:self.playingVideoCell];
        return;
    }

    // handle the first cell cannot play video when initialized.
    [self handleCellUnreachableTypeInVisibleCellsAfterReloadData];
    
    NSArray<UITableViewCell *> *visibleCells = [self.tableView visibleCells];
    // Find first cell need play video in visible cells.
    UITableViewCell *targetCell = nil;
    if(self.playVideoInVisibleCellsBlock){
       targetCell = self.playVideoInVisibleCellsBlock(visibleCells);
    } 
    else {
        for (UITableViewCell *cell in visibleCells) {
            if (cell.wjk_videoURL.absoluteString.length > 0) {
                targetCell = cell;
                break;
            }
        }
    }

    // Play if found.
    if (targetCell) {
        [self playVideoWithCell:targetCell];
    }
}

- (void)stopPlayIfNeed {
    [self.playingVideoCell.wjk_videoPlayView wjk_stopPlay];
    self.playingVideoCell = nil;
}

- (void)scrollViewDidScroll {
    [self handleQuickScrollIfNeed];
}

- (void)scrollViewDidEndDraggingWillDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        [self handleScrollStopIfNeed];
    }
}

- (void)scrollViewDidEndDecelerating {
    [self handleScrollStopIfNeed];
}

- (BOOL)viewIsVisibleInVisibleFrameAtScrollViewDidScroll:(UIView *)view {
    return [self viewIsVisibleInTableViewVisibleFrame:view];
}


#pragma mark - Private

- (BOOL)playingCellIsVisible {
    if(CGRectIsEmpty(self.tableViewVisibleFrame)){
        return NO;
    }
    if(!self.playingVideoCell){
        return NO;
    }

    UIView *strategyView = self.scrollPlayStrategyType == WJKScrollPlayStrategyTypeBestCell ? self.playingVideoCell : self.playingVideoCell.wjk_videoPlayView;
    if(!strategyView){
        return NO;
    }
    return [self viewIsVisibleInTableViewVisibleFrame:strategyView];
}

- (BOOL)viewIsVisibleInTableViewVisibleFrame:(UIView *)view {
    CGRect referenceRect = [self.tableView.superview convertRect:self.tableViewVisibleFrame toView:nil];
    CGPoint viewLeftTopPoint = view.frame.origin;
    viewLeftTopPoint.y += 1;
    CGPoint topCoordinatePoint = [view.superview convertPoint:viewLeftTopPoint toView:nil];
    BOOL isTopContain = CGRectContainsPoint(referenceRect, topCoordinatePoint);

    CGFloat viewBottomY = viewLeftTopPoint.y + view.bounds.size.height;
    viewBottomY -= 2;
    CGPoint viewLeftBottomPoint = CGPointMake(viewLeftTopPoint.x, viewBottomY);
    CGPoint bottomCoordinatePoint = [view.superview convertPoint:viewLeftBottomPoint toView:nil];
    BOOL isBottomContain = CGRectContainsPoint(referenceRect, bottomCoordinatePoint);
    if(!isTopContain && !isBottomContain){
        return NO;
    }
    return YES;
}

- (UITableViewCell *)findTheBestPlayVideoCell {
    if(CGRectIsEmpty(self.tableViewVisibleFrame)){
        return nil;
    }

    // To find next cell need play video.
    UITableViewCell *targetCell = nil;
    UITableView *tableView = self.tableView;
    NSArray<UITableViewCell *> *visibleCells = [tableView visibleCells];
    if(self.findBestCellInVisibleCellsBlock){
        return self.findBestCellInVisibleCellsBlock(visibleCells);
    }
    
    CGFloat gap = MAXFLOAT;
    CGRect referenceRect = [tableView.superview convertRect:self.tableViewVisibleFrame toView:nil];

    for (UITableViewCell *cell in visibleCells) {
        if (!(cell.wjk_videoURL.absoluteString.length > 0)) {
            continue;
        }

        // If need to play video.
        // Find the cell cannot stop in screen center first.
        UIView *strategyView = self.scrollPlayStrategyType == WJKScrollPlayStrategyTypeBestCell ? cell : cell.wjk_videoPlayView;
        if(!strategyView){
            continue;
        }
        if (cell.wjk_unreachableCellType != WJKVideoPlayerUnreachableCellTypeNone) {
            // Must the all area of the cell is visible.
            if (cell.wjk_unreachableCellType == WJKVideoPlayerUnreachableCellTypeTop) {
                CGPoint strategyViewLeftUpPoint = strategyView.frame.origin;
                strategyViewLeftUpPoint.y += 2;
                CGPoint coordinatePoint = [strategyView.superview convertPoint:strategyViewLeftUpPoint toView:nil];
                if (CGRectContainsPoint(referenceRect, coordinatePoint)){
                    targetCell = cell;
                    break;
                }
            }
            else if (cell.wjk_unreachableCellType == WJKVideoPlayerUnreachableCellTypeDown){
                CGPoint strategyViewLeftUpPoint = cell.frame.origin;
                CGFloat strategyViewDownY = strategyViewLeftUpPoint.y + cell.bounds.size.height;
                CGPoint strategyViewLeftDownPoint = CGPointMake(strategyViewLeftUpPoint.x, strategyViewDownY);
                strategyViewLeftDownPoint.y -= 1;
                CGPoint coordinatePoint = [strategyView.superview convertPoint:strategyViewLeftDownPoint toView:nil];
                if (CGRectContainsPoint(referenceRect, coordinatePoint)){
                    targetCell = cell;
                    break;
                }
            }
        }
        else{
            CGPoint coordinateCenterPoint = [strategyView.superview convertPoint:strategyView.center toView:nil];
            CGFloat delta = fabs(coordinateCenterPoint.y - referenceRect.size.height * 0.5 - referenceRect.origin.y);
            if (delta < gap) {
                gap = delta;
                targetCell = cell;
            }
        }
    }

    return targetCell;
}

- (NSUInteger)fetchUnreachableCellCountWithVisibleCellsCount:(NSUInteger)visibleCellsCount {
    if(![self.unreachableCellDictionary.allKeys containsObject:[NSString stringWithFormat:@"%d", (int)visibleCellsCount]]){
        return 0;
    }
    return [[self.unreachableCellDictionary valueForKey:[NSString stringWithFormat:@"%d", (int)visibleCellsCount]] intValue];
}

- (NSDictionary<NSString *, NSString *> *)unreachableCellDictionary {
    if(!_unreachableCellDictionary){
        // The key is the number of visible cells in screen,
        // the value is the number of cells cannot stop in screen center.
        _unreachableCellDictionary = @{
                @"4" : @"1",
                @"3" : @"1",
                @"2" : @"0"
        };
    }
    return _unreachableCellDictionary;
}

- (void)playVideoWithCell:(UITableViewCell *)cell {
    NSParameterAssert(cell);
    if(!cell){
        return;
    }

    self.playingVideoCell = cell;
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:willPlayVideoOnCell:)]) {
        [self.delegate tableView:self.tableView willPlayVideoOnCell:cell];
    }
}

- (void)handleQuickScrollIfNeed {
    if (!self.playingVideoCell) {
        return;
    }

    // Stop play when the cell playing video is un-visible.
    if (![self playingCellIsVisible]) {
        [self stopPlayIfNeed];
    }
}

- (void)handleScrollStopIfNeed {
    UITableViewCell *bestCell = [self findTheBestPlayVideoCell];
    if(!bestCell){
        return;
    }

    // If the found cell is the cell playing video, this situation cannot play video again.
    if([bestCell wjk_isEqualToCell:self.playingVideoCell]){
        return;
    }

    [self.playingVideoCell.wjk_videoPlayView wjk_stopPlay];
    [self playVideoWithCell:bestCell];
}

@end

static NSString * const WJKMigrationLastSDKVersionKey = @"com.wjkvideoplayer.last.migration.version.www";
@implementation WJKMigration

+ (void)migrateToSDKVersion:(NSString *)version
                      block:(dispatch_block_t)migrationBlock {
    // version > lastMigrationVersion
    if ([version compare:[self lastMigrationVersion] options:NSNumericSearch] == NSOrderedDescending) {
        migrationBlock();
        WJKDebugLog(@"JPMigration: Running migration for version %@", version);
        [self setLastMigrationVersion:version];
        }
    }

+ (NSString *)lastMigrationVersion {
    NSString *res = [[NSUserDefaults standardUserDefaults] valueForKey:WJKMigrationLastSDKVersionKey];
    return (res ? res : @"");
}

+ (void)setLastMigrationVersion:(NSString *)version {
    [[NSUserDefaults standardUserDefaults] setValue:version forKey:WJKMigrationLastSDKVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    }

@end
    
NS_ASSUME_NONNULL_END
