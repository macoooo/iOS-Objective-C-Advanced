//
//  ViewController.h
//  KVO
//
//  Created by 强淑婷 on 2019/8/5.
//  Copyright © 2019 强淑婷. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
- (void)foo;
- (void)foo:(NSString *)name;
- (void)foo:(NSString *)name x:(NSString *)x;

@end

