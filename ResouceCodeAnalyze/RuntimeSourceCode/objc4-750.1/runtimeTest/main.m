//
//  main.m
//  runtimeTest
//
//  Created by lonlife on 2019/3/15.
//

#import <Foundation/Foundation.h>
#import "objc-runtime.h"
#import "Person.h"
#import "Person+Fly.h"

// 把一个十进制的数转为二进制
NSString * binaryWithInteger(NSUInteger decInt){
    NSString *string = @"";
    NSUInteger x = decInt;
    while(x > 0){
        string = [[NSString stringWithFormat:@"%lu",x&1] stringByAppendingString:string];
        x = x >> 1;
    }
    return string;
}

int main(int argc, const char * argv[]) {
    // 整个程序都包含在一个@autoreleasepool中
    //id __strong obj = [NSMutableArray array];
//    NSObject *obj0 = [[NSObject alloc] init];
//    NSObject *obj1 __weak = obj0;
//    printf("retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(obj0))); //结果为1
//
//    printf("retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(obj1)));
    @autoreleasepool {
        
//        NSObject *obj = [[NSObject alloc] init];
//        NSObject __weak *obj1 = obj;
//        NSObject *obj2 = obj1;
//        //id __weak obj2;
//        // insert code here...
        Person *p = [[Person alloc] init];
        //[p addObserver:p forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [p say];
        [p fly];
        Person *personTwo = [Person somePerson];

    }
    return 0;
}
