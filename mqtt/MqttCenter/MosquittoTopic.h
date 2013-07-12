//
//  MosquittoTopic.h
//  mqtt
//
//  Created by YANG HONGBO on 2013-7-12.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MosquittoCenter.h"

@interface MosquittoTopic : NSObject
@property (nonatomic, strong, readonly) NSString *string;
@property (nonatomic, assign, readonly) MqttQos qos;
@end
