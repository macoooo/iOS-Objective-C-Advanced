//
//  ViewController.m
//  KVO
//
//  Created by 强淑婷 on 2019/8/5.
//  Copyright © 2019 强淑婷. All rights reserved.
//

#import "ViewController.h"
#import "objc/runtime.h"
#import "Student.h"
#import "NSObject+KVOBlock.h"
#import "objc/message.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    Method method = class_getInstanceMethod([self class], NSSelectorFromString(@"foo"));
    IMP imp1 = method_getImplementation(method);
    NSLog(@"%p", imp1);
    
    Method method2 = class_getInstanceMethod([self class], NSSelectorFromString(@"foo:x:"));
    IMP imp2 = method_getImplementation(method2);
    NSLog(@"%p", imp2);
    
    Method method3 = class_getInstanceMethod([Student class], NSSelectorFromString(@"foo"));
    IMP imp3 = method_getImplementation(method3);
    NSLog(@"%p", imp3);
    
    Student *std = [Student new];
    std.name = @"Tom";
    NSLog(@"std->isa:%@", object_getClass(std));
    NSLog(@"std class:%@", [std class]);
    NSLog(@"ClassMethodNames:%@", ClassMethodNames(object_getClass(std)));
    [std showObjectInfo];

    [std addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [std addObserver:self forKeyPath:@"friends" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    Class objectRuntimeClass = object_getClass(std);
    Class superClass = class_getSuperclass(objectRuntimeClass);
    NSLog(@"super class is %@", superClass);

    NSLog(@"std->isa:%@", object_getClass(std));
    NSLog(@"std class:%@", [std class]);
    NSLog(@"ClassMethodNames:%@", ClassMethodNames(object_getClass(std)));
    [std showObjectInfo];


    [std removeObserver:self forKeyPath:@"name"];
    [std removeObserver:self forKeyPath:@"friends"];
    NSLog(@"std->isa:%@", object_getClass(std));
    NSLog(@"std class:%@", [std class]);
    NSLog(@"ClassMethodNames:%@", ClassMethodNames(object_getClass(std)));
    [std showObjectInfo];
    
//    Student *std = [Student new];
//    [std sw_addObserver:self forKeyPath:@"name" callBack:^(id  _Nonnull observedObject, NSString * _Nonnull observedKeyPath, id  _Nonnull oldValue, id  _Nonnull newValue) {
//        NSLog(@"old value is %@, new value is %@", oldValue, newValue);
//    }];
//
//    std.name = @"Hello";
//    std.name = @"Lilhy";
//    NSLog(@"Class is %@, object_class is %@", [std class], object_getClass(std));
//    [std sw_removeObserver:self forKeyPath:@"name"];
//    NSLog(@"class is %@, object_class is %@", [std class], object_getClass(std));
    
    // Do any additional setup after loading the view.
}
- (void)foo {
    NSLog(@"foo");
}
- (void)foo:(NSString *)name {
    NSLog(@"foo Name");
}
- (void)foo:(NSString *)name x:(NSString *)x {
    NSLog(@"foo Name");
    
}
static NSArray * ClassMethodNames(Class c) {
    NSMutableArray *array = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(c, &methodCount);
    unsigned int i;
    for (i = 0; i < methodCount; i++) {
        [array addObject:NSStringFromSelector(method_getName(methodList[i]))];
    }
    free(methodList);
    return  array;
}
@end
