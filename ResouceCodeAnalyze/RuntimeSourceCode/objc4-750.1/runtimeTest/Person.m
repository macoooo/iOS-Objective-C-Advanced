//
//  Person.m
//  runtimeTest
//
//  Created by lonlife on 2019/3/21.
//

#import "Person.h"

@implementation Person

- (void)say
{
    NSLog(@"hello,world!");
}

+ (Person *)somePerson {
    Person *person = [[Person alloc] init];
    return person;
}
@end
