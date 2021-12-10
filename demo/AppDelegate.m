//
//  AppDelegate.m
//  Map4dMap Utils Development Demo
//
//  Created by Huy Dang on 12/3/21.
//

#import "AppDelegate.h"
#import <Map4dMap/Map4dMap.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSAssert(false, @"Provide a valid key registered with the demo app bundle id. Then delete this line.");
  [MFServices provideAccessKey:@""];
  return YES;
}

@end
