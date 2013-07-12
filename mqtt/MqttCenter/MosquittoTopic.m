//
//  MosquittoTopic.m
//  mqtt
//
//  Created by YANG HONGBO on 2013-7-12.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import "MosquittoTopic.h"

@interface MosquittoTopic ()
@property (nonatomic, strong, readwrite) NSString *string;
@property (nonatomic, assign, readwrite) MqttQos qos;

@end

@implementation MosquittoTopic
- (id)initWithTopic:(NSString *)topic qos:(MqttQos)qos
{
    self = [super init];
    if (self) {
        self.string = topic;
        self.qos = qos;
    }
    return self;
}
@end
