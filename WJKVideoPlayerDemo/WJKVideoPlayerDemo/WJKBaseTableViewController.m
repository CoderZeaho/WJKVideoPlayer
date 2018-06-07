//
//  WJKBaseTableViewController.m
//  iOSwujike
//
//  Created by Zeaho on 2017/8/3.
//  Copyright © 2017年 xhb_iOS. All rights reserved.
//

#import "WJKBaseTableViewController.h"

@interface WJKBaseTableViewController ()

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, assign) UITableViewStyle style;

@end

@implementation WJKBaseTableViewController {
    NSArray *_sectionIndexTitles;
}

- (instancetype)initWithStyle:(UITableViewStyle)style;{
    if (self = [self init]) {
        self.style = style;
        
        [self initialize];
        
    }
    return self;
}

- (void)initialize{
    
}

- (void)loadView{
    [super loadView];
    
//    if (!_tableView) {
//        [[self view] addSubview:[self tableView]];
//    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.contentOffset = CGPointMake(0, - [self contentInset].top);
    self.tableView.contentInset = [self contentInset];
    self.tableView.scrollIndicatorInsets = [self contentInset];
    self.tableView.sectionIndexColor = [UIColor darkGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexMinimumDisplayRowCount = 20;
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
}

#pragma mark - accessor

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)) style:[self style]];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.backgroundColor = [UIColor whiteColor];
        [[self view] addSubview:_tableView];
        
    }
    return _tableView;
}

- (NSArray *)dataSource{
    if (!_dataSource) {
        _dataSource = @[];
    }
    return _dataSource;
}

- (NSArray *)sectionIndexTitles{
    if (!_sectionIndexTitles) {
        _sectionIndexTitles = @[];
    }
    return _sectionIndexTitles;
}

- (void)setSectionIndexTitles:(NSArray *)sectionIndexTitles{
    if (_sectionIndexTitles != sectionIndexTitles) {
        _sectionIndexTitles = sectionIndexTitles;
        
        [[self tableView] reloadData];
    }
}

- (CGFloat)topBarHeight{
    
    BOOL isNavigationbarDisplay = [self navigationController] && ![[self navigationController] isNavigationBarHidden];
    BOOL isStatusBarDisplay = ![[UIApplication sharedApplication] isStatusBarHidden];
    
    return isNavigationbarDisplay * 44.f + isStatusBarDisplay * (([[UIScreen mainScreen] bounds].size.height - 812.f) ? 20 : 44);
}

- (CGFloat)bottomBarHeight{
    
    BOOL isToolBarDisplay = [self navigationController] && ![[self navigationController] isToolbarHidden];
    BOOL isTabBarDisplay = [self tabBarController] && ![[[self tabBarController] tabBar] isHidden];
    
    return isToolBarDisplay * ([[UIApplication sharedApplication] statusBarFrame].size.height > 20 ? 83 : 49) + isTabBarDisplay * ([[UIApplication sharedApplication] statusBarFrame].size.height > 20 ? 83 : 49);
}

- (UIEdgeInsets)contentInset {
    return UIEdgeInsetsMake([self topBarHeight], 0, [self bottomBarHeight], 0);
}

- (void)setView:(UIView *)view {
    [super setView:view];
    if ([view isKindOfClass:UITableView.class]) {
        self.tableView = (UITableView *)view;
    }
}

#pragma mark - public

- (void)reloadData {
    [[self tableView] reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self dataSource] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self dataSource][section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section >= [[self sectionIndexTitles] count]) return nil;
    return [self sectionIndexTitles][section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
