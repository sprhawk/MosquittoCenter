//
//  MosquittoMessage.m
//  mqtt
//
//  Created by YANG HONGBO on 2013-7-12.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import "MosquittoMessage.h"

@interface MosquittoMessage ()
{
}

@property (nonatomic, copy, readwrite) MosquittoTopic * topic;
@property (nonatomic, assign, readwrite) MqttQos qos;
@property (nonatomic, copy, readwrite) NSData * data;
@end

@implementation MosquittoMessage

+ (id)messageWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos data:(NSData *)data;
{
    return [[MosquittoMessage alloc] initWithTopic:topic qos:qos data:data];
}

- (id)initWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos data:(NSData *)data
{
    self = [super init];
    if (self) {
        self.topic = topic;
        self.qos = qos;
        self.data = data;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    MosquittoMessage * msg = [[MosquittoMessage allocWithZone:zone] initWithTopic:self.topic qos:self.qos data:self.data];
    return msg;
}

@end

@interface MutableMosquittoMessage ()
{
    NSMutableData * _mutableData;
}
@end

@implementation MutableMosquittoMessage

+ (id)messageWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos
{
    return [[MutableMosquittoMessage alloc] initWithTopic:topic qos:qos];
}

- (id)initWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos data:(NSData *)data
{
    self = [super initWithTopic:topic qos:qos data:nil];
    if (self) {
        _mutableData = [NSMutableData dataWithCapacity:data.length];
        if (data) {
            [_mutableData appendData:data];
        }
    }
    return self;
}

- (id)initWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos
{
    self = [super initWithTopic:topic qos:qos data:nil];
    return self;
}

- (void)appendPayloadData:(NSData *)data
{
    [_mutableData appendData:data];
}

- (NSData *)data
{
    NSData * data = [_mutableData copy];
    return data;
}

- (void)setData:(NSData *)data
{
    if (data) {
        [_mutableData setData:data];
    }
    else {
        [_mutableData setLength:0];
    }
}

@end