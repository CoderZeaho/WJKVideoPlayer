//
//  ViewController.m
//  WJKVideoPlayerDemo
//
//  Created by Zeaho on 2018/6/6.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "ViewController.h"
#import "WJKBasicVideoPlayerViewController.h"

typedef void (^TableRowBlock)(void);

@interface ViewController ()

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"播放器";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _initializeDefaultData];
}

- (void)_initializeDefaultData {
    self.dataSource = @[
                        @[
                            @{@"title":@"基础播放器",@"description":@"",@"action":^{[self _transitMessageViewController];}}
                            ],
                        ];
    
    [[self tableView] reloadData];
}

- (void)_transitMessageViewController {
    WJKBasicVideoPlayerViewController *basicVideoPlayerViewController = [[WJKBasicVideoPlayerViewController alloc] init];
    [[self navigationController] pushViewController:basicVideoPlayerViewController animated:YES];
}

#pragma mark - accessor
- (UIEdgeInsets)contentInset{
    return UIEdgeInsetsMake(0, 0, 0, 0);
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
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TableRowBlock block = self.dataSource[[indexPath section]][[indexPath row]][@"action"];
    block();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
