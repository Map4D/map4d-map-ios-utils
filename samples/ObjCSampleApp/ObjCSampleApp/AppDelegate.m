//
//  AppDelegate.m
//  ObjCSampleApp
//
//  Created by Huy Dang on 06/12/2021.
//  Copyright © 2021 IOTLink. All rights reserved.
//

#import "AppDelegate.h"
#import <Map4dMap/MFServices.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSAssert(false, @"Provide a valid key registered with the demo app bundle id. Then delete this line.");
  [MFServices provideAccessKey:@""];

  return YES;
}

@end
