//
//  ViewController.m
//  ObjCSampleApp
//
//  Created by Huy Dang on 06/12/2021.
//  Copyright © 2021 IOTLink. All rights reserved.
//

#import "ViewController.h"
#import <Map4dMapUtils/MarkerCluster.h>

static const NSUInteger kClusterItemCount = 500;
static const double kCameraLatitude = 16.0432432;
static const double kCameraLongitude = 108.032432;

@interface ViewController ()

@end

@implementation ViewController {
  MFMapView *_mapView;
  MFUClusterManager *_clusterManager;
}

- (void)loadView {
  _mapView = [[MFMapView alloc] initWithFrame:CGRectZero];
  self.view = _mapView;
  
  CLLocationCoordinate2D target = CLLocationCoordinate2DMake(kCameraLatitude, kCameraLongitude);
  MFCameraPosition* camera = [[MFCameraPosition alloc] initWithTarget:target zoom:10];
  [_mapView moveCamera:[MFCameraUpdate setCamera:camera]];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // id<MFUClusterAlgorithm> algorithm = [[MFUNonHierarchicalDistanceBasedAlgorithm alloc] init];
  id<MFUClusterAlgorithm> algorithm = [[MFUGridBasedClusterAlgorithm alloc] init];
  
  id<MFUClusterIconGenerator> iconGenerator = [[MFUDefaultClusterIconGenerator alloc] init];
  id<MFUClusterRenderer> renderer =
      [[MFUDefaultClusterRenderer alloc] initWithMapView:_mapView
                                    clusterIconGenerator:iconGenerator];
  _clusterManager =
      [[MFUClusterManager alloc] initWithMap:_mapView algorithm:algorithm renderer:renderer];

  // Register self to listen to MFMapViewDelegate events.
  [_clusterManager setMapDelegate:(id<MFMapViewDelegate>)self];

  // Generate and add random items to the cluster manager.
  [self generateClusterItems];

  // Call cluster() after items have been added to perform the clustering and rendering on map.
  [_clusterManager cluster];
}

#pragma mark MFMapViewDelegate

- (BOOL)mapview:(MFMapView *)mapView didTapMarker:(MFMarker *)marker {
  [_mapView animateCamera:[MFCameraUpdate setTarget:marker.position]];
  if ([marker.userData conformsToProtocol:@protocol(MFUCluster)]) {
    [_mapView animateCamera:[MFCameraUpdate setTarget:_mapView.camera.target
                                                 zoom:_mapView.camera.zoom + 1]];
    NSLog(@"Did tap marker cluster");
    return YES;
  }
  NSLog(@"Did tap marker");
  return NO;
}

#pragma mark Private

// Randomly generates cluster items within some extent of the camera and adds them to the
// cluster manager.
- (void)generateClusterItems {
  const double extent = 0.2;
  for (int index = 1; index <= kClusterItemCount; ++index) {
    double lat = kCameraLatitude + extent * [self randomScale];
    double lng = kCameraLongitude + extent * [self randomScale];
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(lat, lng);
    MFMarker *marker = [[MFMarker alloc] init];
    marker.position = position;
    // marker.icon = [UIImage imageNamed:@"ic_marker_tracking"];
    // marker.userInteractionEnabled = NO;
    [_clusterManager addItem:(id<MFUClusterItem>)marker];
  }
}

// Returns a random value between -1.0 and 1.0.
- (double)randomScale {
  return (double)arc4random() / UINT32_MAX * 2.0 - 1.0;
}


@end
