//
//  NSObject+KVOBlock.h
//  KVO
//
//  Created by 强淑婷 on 2019/8/5.
//  Copyright © 2019 强淑婷. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef void(^sw_KVOObserverBlock)(id observedObject, NSString *observedKeyPath,id oldValue, id newValue);
@interface NSObject (KVOBlock)

- (void)sw_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath callBack:(sw_KVOObserverBlock)callback;
- (void)sw_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
