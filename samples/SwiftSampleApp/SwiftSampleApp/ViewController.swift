//
//  ViewController.swift
//  SwiftSampleApp
//
//  Created by Huy Dang on 06/12/2021.
//  Copyright © 2021 IOTLink. All rights reserved.
//

import UIKit
import Map4dMapUtils

let kClusterItemCount = 500;
let kCameraLatitude = 16.0432432;
let kCameraLongitude = 108.032432;

class ViewController: UIViewController, MFMapViewDelegate {
  
  private var mapView: MFMapView!
  private var clusterManager: MFUClusterManager!
  
  override func loadView() {
    super.loadView()
    mapView = MFMapView(frame: .zero)
    self.view = mapView;
    
    let target = CLLocationCoordinate2DMake(kCameraLatitude, kCameraLongitude);
    let camera = MFCameraPosition(target: target, zoom: 10)
    mapView.moveCamera(MFCameraUpdate.setCamera(camera))
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set up the cluster manager with default icon generator and renderer.
    let iconGenerator = MFUDefaultClusterIconGenerator()
    let algorithm = MFUNonHierarchicalDistanceBasedAlgorithm()
    let renderer = MFUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
    clusterManager = MFUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
    
    // Register self to listen to GMSMapViewDelegate events.
    clusterManager.setMapDelegate(self)
    
    // Generate and add random items to the cluster manager.
    generateClusterItems()

    // Call cluster() after items have been added to perform the clustering and rendering on map.
    clusterManager.cluster()
  }
  
  func mapview(_ mapView: MFMapView!, didTap marker: MFMarker!) -> Bool {
    mapView.animateCamera(MFCameraUpdate.setTarget(marker.position))
    if let _ = marker.userData as? MFUCluster {
      mapView.animateCamera(MFCameraUpdate.setTarget(mapView.camera!.target, zoom: mapView.camera!.zoom + 1))
      NSLog("Did tap marker cluster")
      return true
    }
    NSLog("Did tap marker")
    return false
  }

  private func generateClusterItems() {
    let extent = 0.2
    for _ in 1...kClusterItemCount {
      let lat = kCameraLatitude + extent * randomScale()
      let lng = kCameraLongitude + extent * randomScale()
      let position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
      let marker = MFMarker()
      marker.position = position
      clusterManager.add(marker)
    }
  }

  /// Returns a random value between -1.0 and 1.0.
  private func randomScale() -> Double {
    return Double(arc4random()) / Double(UINT32_MAX) * 2.0 - 1.0
  }

}

