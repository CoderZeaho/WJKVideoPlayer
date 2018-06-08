//
//  WJKBasicVideoPlayerViewController.m
//  WJKVideoPlayerDemo
//
//  Created by Zeaho on 2018/6/7.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "WJKBasicVideoPlayerViewController.h"
#import "WJKVideoPlayerBasicControlView.h"

// tools
#import "WJKVideoPlayerKit.h"

static const CGFloat kVideoPlayerHeight = 200.f;

@interface WJKBasicVideoPlayerViewController () <WJKVideoPlayerDelegate, WJKVideoPlayerBasicControlViewDelegate>

/** 视频容器 */
@property (nonatomic, strong) UIView *videoContainer;
/** 播放器控制层 */
@property (nonatomic, strong) WJKVideoPlayerBasicControlView *controlView;

@end

@implementation WJKBasicVideoPlayerViewController

- (void)dealloc {
    
    // 视频停止播放
    [[self videoContainer] wjk_stopPlay];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIView *videoContainerBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, kVideoPlayerHeight + (iPhoneX ? kStatusBarHeight : 0))];
    videoContainerBackgroundView.backgroundColor = [UIColor blackColor];
    [[self view] addSubview:videoContainerBackgroundView];
    
    // 初始化播放器控制层
    self.controlView = [[WJKVideoPlayerBasicControlView alloc] initWithControlBar:nil blurImage:nil needAutoHideControlView:YES];
    self.controlView.delegate = self;
    
    // 初始化播放器
    self.videoContainer = [[UIView alloc] initWithFrame:CGRectMake(0, iPhoneX ? kStatusBarHeight : 0, SCREENWIDTH, kVideoPlayerHeight)];
    self.videoContainer.wjk_videoPlayerDelegate = self;
    self.videoContainer.backgroundColor = [UIColor blackColor];
    [[self view] addSubview:[self videoContainer]];
    [[self videoContainer] wjk_playVideoWithURL:[NSURL URLWithString:@"xpher.me"]
                             bufferingIndicator:nil
                                    controlView:[self controlView]
                                   progressView:nil
                        configurationCompletion:nil];
    
    // 初始化默认数据
    [self _initializeDefaultData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
    
    [[self navigationController] setNavigationBarHidden:YES animated:animated];
    
    if (self.videoContainer.wjk_playerStatus == WJKVideoPlayerStatusPause) {
        [[self videoContainer] wjk_resume];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[self navigationController] setNavigationBarHidden:NO animated:animated];
    
    if (self.videoContainer.wjk_playerStatus == WJKVideoPlayerStatusPlaying) {
        [[self videoContainer] wjk_resume];
    }
}

- (void)_initializeDefaultData {
    self.dataSource = @[
                        @[
                            @{@"title":@"空空如也",@"description":@"",@"action":^{}}
                            ],
                        ];
    
    [[self videoContainer] wjk_playVideoWithURL:[NSURL URLWithString:@"http://aliyunvideo.wujike.com.cn/2e4a16536b514694b5fa6f3171abb2d6/f6c42b9d33a24d51948dbbb1c225bec4-b0f1e12fbe770573528d470ab256055d-sd.mp4"]
                             bufferingIndicator:nil
                                    controlView:[self controlView]
                                   progressView:nil
                        configurationCompletion:nil];
    
    [[self tableView] reloadData];
}

#pragma mark - WJKVideoPlayerBasicControlViewDelegate
- (void)popBack {
    
    [[self videoContainer] wjk_stopPlay];
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)videoPlayerControlView:(WJKVideoPlayerBasicControlView *)controlView clickBackButton:(UIButton *)button completion:(void (^)(BOOL))completion
{
    if (self.videoContainer.wjk_viewInterfaceOrientation == WJKVideoPlayViewInterfaceOrientationLandscape) {
        [[self videoContainer] wjk_gotoPortrait];
        if (completion) {
            completion(NO);
        }
    } else if (self.videoContainer.wjk_viewInterfaceOrientation == WJKVideoPlayViewInterfaceOrientationPortrait) {
        [self popBack];
    }
}

#pragma mark - accessor
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIEdgeInsets)contentInset{
    return UIEdgeInsetsMake(iPhoneX ? kStatusBarHeight + kVideoPlayerHeight : kVideoPlayerHeight, 0, 0, 0);
}

#pragma mark - tableView delegate && datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self dataSource] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sectionDataSource = self.dataSource[section];
    return [sectionDataSource count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionDataSource = self.dataSource[[indexPath section]];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([UITableViewCell class])];
    }
    NSDictionary *info = sectionDataSource[[indexPath row]];
    cell.textLabel.text = info[@"title"];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
