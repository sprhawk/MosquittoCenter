//
//  MosquittoMessage.h
//  mqtt
//
//  Created by YANG HONGBO on 2013-7-12.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MosquittoCenter.h"
#import "MosquittoTopic.h"

@interface MosquittoMessage : NSObject <NSCopying>
@property (nonatomic, copy, readonly) MosquittoTopic * topic;
@property (nonatomic, assign, readonly) MqttQos qos;
@property (nonatomic, assign, readwrite) BOOL needRetain;
@property (nonatomic, copy, readonly) NSData *data;
+ (id)messageWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos data:(NSData *)data;
- (id)initWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos data:(NSData *)data;
@end

@interface MutableMosquittoMessage : MosquittoMessage
+ (id)messageWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos;
- (id)initWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos;
- (void)appendPayloadData:(NSData *)data;
@end

