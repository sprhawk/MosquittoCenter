//
//  AppDelegate.m
//  mqtt
//
//  Created by YANG HONGBO on 2013-7-10.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import "AppDelegate.h"
#import "MosquittoCenter.h"
#import "MosquittoTopic.h"
#import "MosquittoMessage.h"

@interface AppDelegate ()
{
    MosquittoCenter * _center;
    NSTimer * _timer;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mosquittoStateChanged:)
                                                 name:MosquittoStateChangedNotification
                                               object:nil];
    _center = [[MosquittoCenter alloc] initWithClientId:@"0000"
                                           cleanSession:YES
                                                   host:@"127.0.0.1"
                                                   port:1883
                                              keepAlive:2 * 60];
    [_center start];
    
    return YES;
}

- (void)mosquittoStateChanged:(NSNotification *)notification
{
    if (MosquittoStateConnected == _center.mosquttoState) {
        [_center subscribe:[MosquittoTopic topicWithTopic:@"xxxx" qos:MqttQosJustOnce]];
        
        if (nil == _timer) {
            _timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(sendMessage:) userInfo:nil repeats:YES];
        }
    }
    else if(MosquittoStateDisconnected == _center.mosquttoState) {
        [_center halt];
        _center = nil;
    }
}

- (void)sendMessage:(NSTimer *)timer
{
    static int i = 0;
    if (MosquittoStateConnected == _center.mosquttoState) {
        MosquittoTopic * t = [MosquittoTopic topicWithTopic:@"xxxx" qos:2];
        MosquittoMessage * m = [MosquittoMessage messageWithTopic:t qos:2 data:[@"test" dataUsingEncoding:NSUTF8StringEncoding]];
        [_center publish:m];
        i ++;
        
        if (i == 5) {
            [_timer invalidate];
            [_center disconnect];
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
