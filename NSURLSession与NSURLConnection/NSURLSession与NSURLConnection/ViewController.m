//
//  ViewController.m
//  NSURLSession与NSURLConnection
//
//  Created by 强淑婷 on 2019/8/8.
//  Copyright © 2019 强淑婷. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()< UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    // Do any additional setup after loading the view.
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 8;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    NSArray *titleArray = [NSArray arrayWithObjects:@"dispatch_set_target", @"DispatchGruop",@"Dispatch_sync",@"Semaphore",@"NSOperation",@"Thread",@"111",@"111",nil];
    cell.textLabel.text = titleArray[indexPath.row];
    return cell;
}

@end
