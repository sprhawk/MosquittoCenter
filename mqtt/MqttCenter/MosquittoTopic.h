//
//  MosquittoTopic.h
//  mqtt
//
//  Created by YANG HONGBO on 2013-7-12.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MosquittoCenter.h"

@interface MosquittoTopic : NSObject<NSCopying>
@property (nonatomic, strong, readonly) NSString *string;
@property (nonatomic, assign, readonly) MqttQos qos;
+ (id)topicWithTopic:(NSString *)topic qos:(MqttQos)qos;
- (id)initWithTopic:(NSString *)topic qos:(MqttQos)qos;
@end
