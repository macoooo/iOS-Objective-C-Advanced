//
//  Person+Fly.m
//  runtimeTest
//
//  Created by lonlife on 2019/3/22.
//

#import "Person+Fly.h"


@implementation Person (Fly)

+  (void)load {
    NSLog(@"load in Category");
}

- (void)setName:(NSString *)name {
    //_name = name;
    objc_setAssociatedObject(self, "name", name, OBJC_ASSOCIATION_COPY);
}

- (NSString *)name {
    NSString *nameObject = objc_getAssociatedObject(self, "name");
    return nameObject;
}
- (void)say {
    NSLog(@"Son's categoey");
}
//实现调取本来类中的say方法
- (void)fly
{
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList([self class], &methodCount);
    
    SEL sel = @selector(say);
    NSString *orginalSelName = NSStringFromSelector(sel);
    IMP lastIMP = nil;
    for (NSInteger i = 0; i < methodCount; i++) {
        Method method = methodList[i];
        NSString *selNAme = NSStringFromSelector(method_getName(method));
        if ([orginalSelName isEqualToString:selNAme]) {
            lastIMP = method_getImplementation(method);
        }
    }
    if (lastIMP != nil) {
        typedef void(*fn) (id, SEL);
        fn f = (fn)lastIMP;
        f(self, sel);
    }
    free(methodList);
}

@end
