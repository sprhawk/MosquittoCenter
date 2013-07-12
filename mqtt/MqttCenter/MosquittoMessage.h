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

@interface MosquittoMessage : NSObject
@property (nonatomic, strong, readonly) MosquittoTopic * topic;
@property (nonatomic, assign, readonly) MqttQos qos;
@property (nonatomic, assign, readwrite) BOOL needRetain;

- (id)initWithTopic:(MosquittoTopic *)topic qos:(MqttQos)qos;
- (void)appendPayloadData:(NSData *)data;
- (NSData *)payload;
@end
