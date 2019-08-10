//
//  SWKVOObserverItem.h
//  KVO
//
//  Created by 强淑婷 on 2019/8/5.
//  Copyright © 2019 强淑婷. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+KVOBlock.h"

NS_ASSUME_NONNULL_BEGIN


@interface SWKVOObserverItem : NSObject

@property (nonatomic, weak) NSObject *observer;
//注意这里是weak，不会对observer做强引用，这样可以消除观察者和被观察者间潜在的循环引用
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) sw_KVOObserverBlock callBack;
@end

NS_ASSUME_NONNULL_END
