//
//  Person.h
//  runtimeTest
//
//  Created by lonlife on 2019/3/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

@property (nonatomic, copy) NSString *name;
- (void)say;
+ (Person *)somePerson;

@end

NS_ASSUME_NONNULL_END
