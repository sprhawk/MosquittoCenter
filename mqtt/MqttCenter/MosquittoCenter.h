//
//  MqttCenter.h
//  mqtt
//
//  Created by YANG HONGBO on 2013-7-12.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mosquitto.h"

typedef enum MosquittoState
{
    MosquittoStateUnknown = 0,
    MosquittoStateInitialized,
    MosquittoStateConnecting,
    MosquittoStateConnectionRefused,
    MosquittoStateConnected,
    MosquittoStateDisconnecting,
    MosquittoStateDisconnected,
}MosquittoState;

typedef enum MosquittoReasonCode {
    MosquittoReasonCodeNoError = 0,
    MosquittoReasonCodeConnectionRefused_UnacceptableProtocalVersion,
    MosquittoReasonCodeConnectionRefused_IdentifierRejected,
    MosquittoReasonCodeConnectionRefused_BrokerUnavailable,
    MosquittoReasonCodeDisconnected_ApplicationInitiated,
    MosquittoReasonCodeDisconnected_Unintentially,
    MosquittoReasonCodeUnknown,
}MosquittoReasonCode;

typedef enum MqttQos {
    MqttQosAtMostOnce = 0,
    MqttQosAtLeastOnce = 1,
    MqttQosJustOnce = 2,
}MqttQos;

extern NSString * const MosquittoStateChangedNotification;

@class MosquittoMessage;
@class MosquittoTopic;

@class MosquittoCenter;
@protocol MosquittoCenterObserver <NSObject>

@end

@interface MosquittoCenter : NSObject
@property (atomic, assign, readwrite) BOOL handleMessageOnMainThread;
@property (atomic, assign, readonly) MosquittoState mosquttoState;
@property (atomic, assign, readonly) MosquittoReasonCode mosquttoReasonCode;
@property (atomic, copy, readonly) NSString *clientId;
@property (atomic, assign, readonly) BOOL cleanSession;
@property (atomic, copy, readonly) NSString *host;
@property (atomic, assign, readonly) NSUInteger port;
@property (atomic, assign, readonly) NSUInteger keepAlive;

- (id)initWithClientId:(NSString *)clientId
          cleanSession:(BOOL)cleanSession
                  host:(NSString *)host
                  port:(NSUInteger)port
             keepAlive:(NSUInteger)keepAlive;
- (BOOL)start;
- (BOOL)disconnect;
- (BOOL)subscribe:(MosquittoTopic *)topic;

- (void)handleUnsubscribeMessageId:(int)messageId;
- (void)handleSubscribeMessageId:(int)messageId qosCount:(int)qosCount grantedQos:(const int *)grantedQos;
- (void)handleMessage:(const struct mosquitto_message *)message;
- (void)handlePublish:(int)messageId;
- (void)registerObserver:(id<MosquittoCenterObserver>)object forTopic:(NSString *)topic;
- (void)removeObserver:(id<MosquittoCenterObserver>)object forTopic:(NSString *)topic;

@end
