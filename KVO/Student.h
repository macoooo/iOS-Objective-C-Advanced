//
//  Student.h
//  KVO
//
//  Created by 强淑婷 on 2019/8/5.
//  Copyright © 2019 强淑婷. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Student : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *friends;
- (void)showObjectInfo;
- (void)foo;
@end

NS_ASSUME_NONNULL_END
