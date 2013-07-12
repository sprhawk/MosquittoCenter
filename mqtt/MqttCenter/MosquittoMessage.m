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
    NSMutableData * _payload;
}

@property (nonatomic, strong, readwrite) MosquittoTopic * topic;
@property (nonatomic, assign, readwrite) MqttQos qos;

@end

@implementation MosquittoMessage
- (id)initWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos
{
    self = [super init];
    if (self) {
        self.topic = topic;
        self.qos = qos;
        
    }
    return self;
}

- (void)appendPayloadData:(NSData *)data
{
    if (nil == _payload) {
        _payload = [NSMutableData dataWithCapacity:data.length];
    }
    [_payload appendData:data];
}

- (NSData *)payload
{
    return [_payload copy];
}

@end
