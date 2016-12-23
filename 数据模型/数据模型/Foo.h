//
//  Foo.h
//  数据模型
//
//  Created by IOS_HMX on 16/12/8.
//  Copyright © 2016年 humingxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXModel.h"
@interface Foo : MXModel
@property (nonatomic , strong) NSArray *array;
@property (nonatomic , assign) NSNumber *count;
@property (nonatomic , copy) NSString *name;
@property (nonatomic , copy , readonly) NSString *age;
@end
