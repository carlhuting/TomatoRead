//
//  LinkViewController.m
//  iOSBlogReader
//
//  Created by everettjf on 16/4/6.
//  Copyright © 2016年 everettjf. All rights reserved.
//

#import "LinkViewController.h"
#import "RestApi.h"
#import "LinkTableViewCell.h"
#import "WebViewController.h"
#import "MainContext.h"
#import <MJRefresh.h>

static NSString * const kLinkCell = @"LinkCell";

@interface LinkViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong,nonatomic) UITableView *tableView;
@property (strong,nonatomic) NSMutableArray<RestLinkModel*> *dataset;
@property (strong,nonatomic) RestLinkListModel *lastQuery;
@property (strong,nonatomic) UIActivityIndicatorView *indicator;
@end

@implementation LinkViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataset = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"link view did load : %@", @(self.item.aspectID));
    
    _tableView = [UITableView new];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[LinkTableViewCell class] forCellReuseIdentifier:kLinkCell];
    [self.view addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.edges.equalTo(self.view);
    }];
    
    _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_pullDown)];
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_pullUp)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    _tableView.mj_footer = footer;
    
    _indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_indicator];
    [_indicator mas_makeConstraints:^(MASConstraintMaker *make){
        make.top.equalTo(self.mas_topLayoutGuide).offset(10);
        make.centerX.equalTo(self.view);
    }];
    [_indicator startAnimating];
    
    [self _loadInitialData];
}

- (void)_loadInitialData{
    [[RestApi api] queryLinkList:self.item.aspectID complete:^(RestLinkListModel *model, NSError *error) {
        [_indicator stopAnimating];
        [_indicator removeFromSuperview];
        _indicator = nil;
        
        if(error) {
            [_tableView.mj_header endRefreshing];
            return;
        }
        self.lastQuery = model;
        
        _dataset = [model.results mutableCopy];
        
        [_tableView reloadData];
        
        [_tableView.mj_header endRefreshing];
        if(!model.next) [_tableView.mj_footer endRefreshingWithNoMoreData];
    } url:nil];
}

- (void)_pullDown{
    [self _loadInitialData];
}

- (void)_pullUp{
    if(!self.lastQuery.next){
        [_tableView.mj_footer endRefreshingWithNoMoreData];
        return;
    }
    
    [[RestApi api] queryLinkList:self.item.aspectID complete:^(RestLinkListModel *model, NSError *error) {
        if(error) {
            [_tableView.mj_footer endRefreshing];
            return;
        }
        self.lastQuery = model;
        
        [_dataset addObjectsFromArray:model.results];
        [_tableView reloadData];
        
        if(model.next) [_tableView.mj_footer endRefreshing];
        else [_tableView.mj_footer endRefreshingWithNoMoreData];
    } url:self.lastQuery.next];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataset.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    LinkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLinkCell forIndexPath:indexPath];
    RestLinkModel *model = [_dataset objectAtIndex:indexPath.row];
    cell.favicon = model.favicon;
    cell.title = model.name;
    
    NSMutableString *subTitle = [NSMutableString new];
    if(model.feed_url && ![model.feed_url isEqualToString:@""])[subTitle appendString:@"[Feed]"];
    if(model.desc) [subTitle appendString:model.desc];
    cell.subTitle = subTitle;
    
    return cell;;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    RestLinkModel *model = [_dataset objectAtIndex:indexPath.row];
    
    WebViewController *webViewController = [[WebViewController alloc]init];
    [[MainContext sharedContext].mainNavigationController pushViewController:webViewController animated:YES];
    webViewController.title = model.name;
    [webViewController loadURLString:model.url];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
