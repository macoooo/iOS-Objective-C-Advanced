//
//  Person+Fly.h
//  runtimeTest
//
//  Created by lonlife on 2019/3/22.
//

#import "Person.h"
#import "objc-runtime.h"

NS_ASSUME_NONNULL_BEGIN

@interface Person (Fly)

@property (nonatomic, copy) NSString *name;

- (void)say;
- (void)fly;

@end

NS_ASSUME_NONNULL_END
