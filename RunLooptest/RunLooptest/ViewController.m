//
//  ViewController.m
//  RunLooptest
//
//  Created by 强淑婷 on 2019/8/6.
//  Copyright © 2019 强淑婷. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        [self performSelector:@selector(foo) withObject:self afterDelay:2];
        [[NSRunLoop currentRunLoop] run];//run方法只是尝试想要开启当前线程中的runloop，但是如果该线程中并没有任何事件(source、timer、observer)的话，并不会成功的开启
        [self performSelector:@selector(foo) withObject:self afterDelay:1];
    });
    UIControl
//    [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
//        NSLog(@"NSTier -- timer 调用了");
//    }];
    // Do any additional setup after loading the view.
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSTimer *timer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(show) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    NSLog(@"%@", [NSRunLoop mainRunLoop]);
    
}
- (void)show {
    NSLog(@"-----");
}
- (void)foo {
    NSLog(@"qst");
}
@end
