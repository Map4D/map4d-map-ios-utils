//
//  AppDelegate.swift
//  SwiftSampleApp
//
//  Created by Huy Dang on 06/12/2021.
//  Copyright © 2021 IOTLink. All rights reserved.
//

import UIKit
import Map4dMap

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    assert(false, "Provide a valid key registered with the demo app bundle id. Then delete this line.");
    MFServices.provideAccessKey("")
    return true
  }

}

