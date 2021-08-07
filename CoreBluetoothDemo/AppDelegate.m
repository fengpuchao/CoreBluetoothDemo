//
//  AppDelegate.m
//  CoreBluetoothDemo
//
//  Created by 冯超 on 2021/7/30.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.window.rootViewController = [[NSClassFromString(@"ViewController")alloc]init];
    [self.window makeKeyWindow];

    return YES;
}

@end
