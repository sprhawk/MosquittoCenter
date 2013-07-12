//
//  MqttCenter.m
//  mqtt
//
//  Created by YANG HONGBO on 2013-7-12.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import "MosquittoCenter.h"
#import "mosquitto.h"
#import "MosquittoTopic.h"
#import "MosquittoMessage.h"

void on_connect(const struct mosquitto *, void *, int);
void on_disconnect(const struct mosquitto *, void *, int);
void on_publish(const struct mosquitto *, void *, int);
void on_subscribe(const struct mosquitto *, void *, int, int, const int *);
void on_unsubscribe(const struct mosquitto *, void *, int);
void on_log(const struct mosquitto *, void *, int, const char *);
void on_message(const struct mosquitto *, void *, const struct mosquitto_message *);

NSString * const MosquittoStateChangedNotification = @"MosquittoStateChangedNotification";

@interface MosquittoCenter ()
{
    NSThread * _mosquittoThread;
    NSLock * _mosquittoThreadExitLock; //prevent from Center exiting before thread exited
    NSMutableDictionary * _topicDelegates;
    
    //variables that should be called from background thread
    struct mosquitto * _mosq;
}
@property (atomic, copy, readwrite) NSString *clientId;
@property (atomic, assign, readwrite) BOOL cleanSession;
@property (atomic, assign, readwrite) MosquittoState mosquttoState;//set state in center to prevent from using mutex lock
@property (atomic, assign, readwrite) MosquittoReasonCode mosquttoReasonCode;
@property (atomic, copy, readwrite) NSString *host;
@property (atomic, assign, readwrite) NSUInteger port;
@property (atomic, assign, readwrite) NSUInteger keepAlive;

//all these callback functions is called in the background thread, so subsequent calls must
//consider multiple-threaded safety
- (void)on_connect:(const struct mosquitto * )mosq result:(int)rc;
- (void)on_disconnect:(const struct mosquitto * )mosq result:(int)rc;
- (void)on_publish:(const struct mosquitto * )mosq messageId:(int)messageId;
- (void)on_message:(const struct mosquitto * )mosq message:(const struct mosquitto_message *)message;
- (void)on_subscribe:(const struct mosquitto * )mosq messageId:(int)messageId qosCount:(int)qosCount grantedQos:(const int *)grantedQos;
- (void)on_unsubscribe:(const struct mosquitto * )mosq messageId:(int)messageId;
- (void)on_log:(const struct mosquitto * )mosq level:(int)level string:(const char *)str;
@end

@implementation MosquittoCenter
@synthesize mosquttoState = _mosquttoState;

+ (void)initialize
{
    mosquitto_lib_init();
}

- (id)initWithClientId:(NSString *)clientId cleanSession:(BOOL)cleanSession host:(NSString *)host port:(NSUInteger)port keepAlive:(NSUInteger)keepAlive
{
    self = [super init];
    if (self) {
        self.clientId = clientId;
        self.cleanSession = cleanSession;
        self.host = host;
        self.port = port;
        self.keepAlive = keepAlive;
        self.handleMessageOnMainThread = YES;
        _mosquittoThreadExitLock = [[NSLock alloc] init];
        _topicDelegates = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return self;
}

- (BOOL)start
{
    if (nil == _mosquittoThread) {
        _mosquittoThread = [[NSThread alloc] initWithTarget:self selector:@selector(mosquittoThreadMethod:) object:nil];
    }
    if (!_mosquittoThread.isExecuting) {
        [_mosquittoThread start];
    }
    return YES;
}

- (BOOL)disconnect
{
    if (_mosq) {
        if (MosquittoStateConnecting == self.mosquttoState
            || MosquittoStateConnected == self.mosquttoState) {
            if ([NSThread currentThread] == _mosquittoThread) {
                mosquitto_disconnect(_mosq);
            }
            else {
                //make _mosq to be used only on MosquittoThread to prevent from using mutex lock
                [self performSelector:@selector(disconnect) onThread:_mosquittoThread withObject:nil waitUntilDone:YES];
            }
        }
    }
    return YES;
}

- (void)registerObserver:(id<MosquittoCenterObserver>)object forTopic:(NSString *)topic
{
    NSMutableSet * delegates = _topicDelegates[topic];
    if (nil == delegates) {
        delegates = [[NSMutableSet alloc] initWithCapacity:1];
        _topicDelegates[topic] = delegates;
    }
    [delegates addObject:object];
}

- (void)removeObserver:(id<MosquittoCenterObserver>)object forTopic:(NSString *)topic
{
    NSMutableSet * delegates = _topicDelegates[topic];
    [delegates addObject:object];
    if (0 == [delegates count]) {
        _topicDelegates[topic] = nil;
    }
}

- (BOOL)subscribe:(MosquittoTopic *)topic
{
    if (_mosq) {
        if ([NSThread currentThread] == _mosquittoThread) {
            int mid = 0;
            const char * sub = [topic.string cStringUsingEncoding:NSUTF8StringEncoding];
            mosquitto_subscribe(_mosq, &mid, sub, (int)topic.qos);
        }
        else {
            //make _mosq to be used only on MosquittoThread to prevent from using mutex lock
            [self performSelector:@selector(subscribe:) onThread:_mosquittoThread withObject:topic waitUntilDone:YES];
        }
        return YES;
    }
    return NO;
}

- (BOOL)publishTopic:(MosquittoTopic *)topic message:(MosquittoMessage *)message
{
    if (_mosq) {
        if ([NSThread currentThread] == _mosquittoThread) {
            int mid = 0;
            const char * str = [topic.string cStringUsingEncoding:NSUTF8StringEncoding];
            NSData * payload = [message payload];
            mosquitto_publish(_mosq, &mid, str, payload.length, payload.bytes, message.qos, message.needRetain);
        }
        else {
            //make _mosq to be used only on MosquittoThread to prevent from using mutex lock
            NSDictionary * param = @{@"topic": topic,
                                     @"qos": [NSNumber numberWithInteger:(int)0]};
            [self performSelector:@selector(subscribe:) onThread:_mosquittoThread withObject:param waitUntilDone:YES];
        }
        return YES;
    }
    return NO;
}

- (void)mosquittoThreadMethod:(id)object
{
    @autoreleasepool {
        [_mosquittoThreadExitLock lock];
        const char * clientId = [self.clientId cStringUsingEncoding:NSUTF8StringEncoding];
        _mosq = mosquitto_new(clientId, self.cleanSession, (__bridge void *)self);
        if (NULL == _mosq) {
            return ;
        }
        self.mosquttoState = MosquittoStateInitialized;
        const char * host = [self.host cStringUsingEncoding:NSUTF8StringEncoding];
        int port = self.port;
        int keepAlive = self.keepAlive;
        mosquitto_connect(_mosq, host, port, keepAlive);
        self.mosquttoState = MosquittoStateConnecting;
        
        NSThread * currentThread = [NSThread currentThread];
        while (!currentThread.isCancelled) {
            NSRunLoop * runLoop = [NSRunLoop currentRunLoop];
            @autoreleasepool {
                [runLoop runMode:NSRunLoopCommonModes beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
                mosquitto_loop(_mosq, -1, 1);//max packets is not used
            }
        }
        [_mosquittoThreadExitLock unlock];
    }
}

- (void)on_connect:(const struct mosquitto * )mosq result:(int)rc
{
    switch (rc) {
        case 0:
            self.mosquttoReasonCode = MosquittoReasonCodeNoError;
            self.mosquttoState = MosquittoStateConnected;
            return;
            break;
        case 1:
            self.mosquttoReasonCode = MosquittoReasonCodeConnectionRefused_UnacceptableProtocalVersion;
            break;
        case 2:
            self.mosquttoReasonCode = MosquittoReasonCodeConnectionRefused_IdentifierRejected;
            break;
        case 3:
            self.mosquttoReasonCode = MosquittoReasonCodeConnectionRefused_BrokerUnavailable;
            break;
        default:
            self.mosquttoReasonCode = MosquittoReasonCodeUnknown;
            break;
    }
    self.mosquttoState = MosquittoStateConnectionRefused;
}

- (void)on_disconnect:(const struct mosquitto * )mosq result:(int)rc
{
    switch (rc) {
        case 0:
            self.mosquttoReasonCode = MosquittoReasonCodeDisconnected_ApplicationInitiated;
            break;
        default:
            self.mosquttoReasonCode = MosquittoReasonCodeDisconnected_Unintentially;
            break;
    }
    self.mosquttoState = MosquittoStateDisconnected;
}

- (void)on_publish:(const struct mosquitto * )mosq messageId:(int)messageId
{
    if (self.handleMessageOnMainThread) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self handlePublish:messageId];
        });
    }
    else {
        [self handlePublish:messageId];
    }
}
- (void)on_message:(const struct mosquitto * )mosq message:(const struct mosquitto_message *)message
{
    if (self.handleMessageOnMainThread) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self handleMessage:message];
        });
    }
    else {
        [self handleMessage:message];
    }
}
- (void)on_subscribe:(const struct mosquitto * )mosq messageId:(int)messageId qosCount:(int)qosCount grantedQos:(const int *)grantedQos
{
    if (self.handleMessageOnMainThread) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self handleSubscribeMessageId:messageId qosCount:qosCount grantedQos:grantedQos];
        });
    }
    else {
        [self handleSubscribeMessageId:messageId qosCount:qosCount grantedQos:grantedQos];
    }
}
- (void)on_unsubscribe:(const struct mosquitto * )mosq messageId:(int)messageId
{
    if (self.handleMessageOnMainThread) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self handleUnsubscribeMessageId:messageId];
        });
    }
    else {
        [self handleUnsubscribeMessageId:messageId];
    }
}

- (void)on_log:(const struct mosquitto * )mosq level:(int)level string:(const char *)str
{
    NSLog(@"mosquitto center: level(%d): %s", level, str);
}

#pragma mark - overridable functions

- (void)handlePublish:(int)messageId
{
    NSLog(@"published:%d", messageId);
}

- (void)handleMessage:(const struct mosquitto_message *)message
{
    NSLog(@"payload:%d", message->payloadlen);
}

- (void)handleSubscribeMessageId:(int)messageId qosCount:(int)qosCount grantedQos:(const int *)grantedQos
{
    NSLog(@"subscribed:%d", messageId);
}

- (void)handleUnsubscribeMessageId:(int)messageId
{
    NSLog(@"unsubscribed:%d", messageId);
}

- (void)setMosquttoState:(MosquittoState)mosquttoState
{
    @synchronized(self) {
        _mosquttoState = mosquttoState;
    }
    NSNotification * n = [NSNotification notificationWithName:MosquittoStateChangedNotification
                                                       object:self
                                                     userInfo:nil];
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [center postNotification:n];
    });
}

- (MosquittoState)mosquttoState
{
    @synchronized(self){
        return _mosquttoState;
    }
}

- (void)dealloc
{
    [_mosquittoThread cancel];
    //prevent object is freed before thread exited
    [_mosquittoThreadExitLock lock];
    if (_mosq) {
        mosquitto_destroy(_mosq);
        _mosq = NULL;
    }
    [_mosquittoThreadExitLock unlock];
}

@end



void on_connect(const struct mosquitto *mosq, void * obj, int rc)
{
    MosquittoCenter * center = (__bridge MosquittoCenter *)obj;
    [center on_connect:mosq result:rc];
}

void on_disconnect(const struct mosquitto *mosq, void *obj, int rc)
{
    MosquittoCenter * center = (__bridge MosquittoCenter *)obj;
    [center on_disconnect:mosq result:rc];
}

void on_publish(const struct mosquitto *mosq, void *obj, int messageid)
{
    MosquittoCenter * center = (__bridge MosquittoCenter *)obj;
    [center on_publish:mosq messageId:messageid];
}

void on_message(const struct mosquitto *mosq, void *obj, const struct mosquitto_message * message)
{
    MosquittoCenter * center = (__bridge MosquittoCenter *)obj;
    [center on_message:mosq message:message];
}

void on_subscribe(const struct mosquitto *mosq, void *obj, int messageid, int qos_count, const int * granted_qos)
{
    MosquittoCenter * center = (__bridge MosquittoCenter *)obj;
    [center on_subscribe:mosq messageId:messageid qosCount:qos_count grantedQos:granted_qos];
}

void on_unsubscribe(const struct mosquitto *mosq, void *obj, int messageid)
{
    MosquittoCenter * center = (__bridge MosquittoCenter *)obj;
    [center on_unsubscribe:mosq messageId:messageid];
}

void on_log(const struct mosquitto *mosq, void *obj, int level, const char * str)
{
    MosquittoCenter * center = (__bridge MosquittoCenter *)obj;
    [center on_log:mosq level:level string:str];
}
