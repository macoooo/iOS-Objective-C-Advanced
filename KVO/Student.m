//
//  Student.m
//  KVO
//
//  Created by 强淑婷 on 2019/8/5.
//  Copyright © 2019 强淑婷. All rights reserved.
//

#import "Student.h"

@implementation Student

- (void)showObjectInfo {
    NSLog(@"Object instance address is %p, Object isa content is %p", self, *((void **)(__bridge void *)self));
}
- (void)foo {
    NSLog(@"std foo");
}
@end
