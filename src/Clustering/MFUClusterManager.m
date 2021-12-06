#import "MFUClusterManager.h"

#import "MFUClusterRenderer.h"
#import "MFUSimpleClusterAlgorithm.h"

// How long to wait for a cluster request before actually performing the clustering operation
// to avoid continuous clustering when the camera is moving which can affect performance.
static const double kMFUClusterWaitIntervalSeconds = 0.2;

@implementation MFUClusterManager {
  // The map view that this object is associated with.
  MFMapView *_mapView;

  // Position of the camera on the previous cluster invocation.
  MFCameraPosition *_previousCamera;

  // Tracks number of cluster requests so that we can safely ignore stale (redundant) ones.
  NSUInteger _clusterRequestCount;

  // Renderer.
  id<MFUClusterRenderer> _renderer;
}

- (instancetype)initWithMap:(MFMapView *)mapView
                  algorithm:(id<MFUClusterAlgorithm>)algorithm
                   renderer:(id<MFUClusterRenderer>)renderer {
  if ((self = [super init])) {
    _algorithm = [[MFUSimpleClusterAlgorithm alloc] init];
    _mapView = mapView;
    _previousCamera = _mapView.camera;
    _algorithm = algorithm;
    _renderer = renderer;
  }

  return self;
}

- (void) setMapDelegate:(id<MFMapViewDelegate> _Nullable)mapDelegate {
  _mapView.delegate = self;
  _mapDelegate = mapDelegate;
}

- (void)setDelegate:(id<MFUClusterManagerDelegate>)delegate
        mapDelegate:(id<MFMapViewDelegate> _Nullable)mapDelegate {
  _delegate = delegate;
  _mapView.delegate = self;
  _mapDelegate = mapDelegate;
}

- (void)addItem:(id<MFUClusterItem>)item {
  [_algorithm addItems:[[NSMutableArray alloc] initWithObjects:item, nil]];
}

- (void)addItems:(NSArray<id<MFUClusterItem>> *)items {
  [_algorithm addItems:items];
}

- (void)removeItem:(id<MFUClusterItem>)item {
  [_algorithm removeItem:item];
}

- (void)clearItems {
  [_algorithm clearItems];
  [self requestCluster];
}

- (void)cluster {
  NSUInteger integralZoom = (NSUInteger)floorf(_mapView.camera.zoom + 0.5f);
  NSArray<id<MFUCluster>> *clusters = [_algorithm clustersAtZoom:integralZoom];
  [_renderer renderClusters:clusters];
  _previousCamera = _mapView.camera;
}

#pragma mark MFMapViewDelegate

- (BOOL)mapview:(MFMapView *)mapView didTapMarker:(MFMarker *)marker {
  if ([_delegate respondsToSelector:@selector(clusterManager:didTapCluster:)] &&
      [marker.userData conformsToProtocol:@protocol(MFUCluster)]) {
    id<MFUCluster> cluster = (id<MFUCluster>)marker.userData;
    if ([_delegate clusterManager:self didTapCluster:cluster]) {
      return YES;
    }
  }

  if ([_delegate respondsToSelector:@selector(clusterManager:didTapClusterItem:)] &&
      [marker.userData conformsToProtocol:@protocol(MFUClusterItem)]) {
    id<MFUClusterItem> clusterItem = (id<MFUClusterItem>)marker.userData;
    if ([_delegate clusterManager:self didTapClusterItem:clusterItem]) {
      return YES;
    }
  }

  // Forward to _mapDelegate as a fallback.
  if ([_mapDelegate respondsToSelector:@selector(mapview:didTapMarker:)]) {
    return [_mapDelegate mapview:mapView didTapMarker:marker];
  }

  return NO;
}

- (void)mapView:(MFMapView *)mapView movingCameraPosition:(MFCameraPosition *)position {
  // Update marker cluster
  [self update];

  // Forward to _mapDelegate as a fallback.
  if ([_mapDelegate respondsToSelector:@selector(mapView:movingCameraPosition:)]) {
    [_mapDelegate mapView:mapView movingCameraPosition:position];
  }
}

- (void)mapView:(MFMapView *)mapView didChangeCameraPosition:(MFCameraPosition *)position {
  // Update marker cluster
  [self update];

  // Forward to _mapDelegate as a fallback.
  if ([_mapDelegate respondsToSelector:@selector(mapView:didChangeCameraPosition:)]) {
    [_mapDelegate mapView:mapView didChangeCameraPosition:position];
  }
}

#pragma mark Delegate Forwards

- (void)mapView:(MFMapView *)mapView willMove:(BOOL)gesture {
  if ([_mapDelegate respondsToSelector:@selector(mapView:willMove:)]) {
    [_mapDelegate mapView:mapView willMove:gesture];
  }
}

- (void)mapView:(MFMapView *)mapView idleAtCameraPosition:(MFCameraPosition *)position {
  if ([_mapDelegate respondsToSelector:@selector(mapView:idleAtCameraPosition:)]) {
    [_mapDelegate mapView:mapView idleAtCameraPosition:position];
  }
}

- (void)mapView:(MFMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
  if ([_mapDelegate respondsToSelector:@selector(mapView:didTapAtCoordinate:)]) {
    [_mapDelegate mapView:mapView didTapAtCoordinate:coordinate];
  }
}

- (void)mapView:(MFMapView *)mapView onModeChange:(bool)is3DMode {
  if ([_mapDelegate respondsToSelector:@selector(mapView:onModeChange:)]) {
    [_mapDelegate mapView:mapView onModeChange:is3DMode];
  }
}

- (void)mapview:(MFMapView *)mapView didTapInfoWindowOfMarker:(MFMarker *)marker {
  if ([_mapDelegate respondsToSelector:@selector(mapview:didTapInfoWindowOfMarker:)]) {
    [_mapDelegate mapview:mapView didTapInfoWindowOfMarker:marker];
  }
}

- (void)mapview:(MFMapView *)mapView didTapPolyline:(MFPolyline *)polyline {
  if ([_mapDelegate respondsToSelector:@selector(mapview:didTapPolyline:)]) {
    [_mapDelegate mapview:mapView didTapPolyline:polyline];
  }
}

- (void)mapview:(MFMapView *)mapView didTapPolygon:(MFPolygon *)polygon {
  if ([_mapDelegate respondsToSelector:@selector(mapview:didTapPolygon:)]) {
    [_mapDelegate mapview:mapView didTapPolygon:polygon];
  }
}

- (void)mapview:(MFMapView *)mapView didTapCircle:(MFCircle *)circle {
  if ([_mapDelegate respondsToSelector:@selector(mapview:didTapCircle:)]) {
    [_mapDelegate mapview:mapView didTapCircle:circle];
  }
}

- (UIView *)mapView:(MFMapView *)mapView markerInfoWindow:(MFMarker *)marker {
  if ([_mapDelegate respondsToSelector:@selector(mapView:markerInfoWindow:)]) {
    return [_mapDelegate mapView:mapView markerInfoWindow:marker];
  }
  return nil;
}

- (void)mapView:(MFMapView *)mapView didTapBuilding:(MFBuilding *)building {
  if ([_mapDelegate respondsToSelector:@selector(mapView:didTapBuilding:)]) {
    [_mapDelegate mapView:mapView didTapBuilding:building];
  }
}

- (void)mapView:(MFMapView *)mapView
    didTapBuildingWithBuildingID:(NSString *)buildingID
                            name:(NSString *)name
                        location:(CLLocationCoordinate2D)location {
  if ([_mapDelegate respondsToSelector:@selector(mapView:didTapBuildingWithBuildingID:name:location:)]) {
    [_mapDelegate mapView:mapView didTapBuildingWithBuildingID:buildingID name:name location:location];
  }
}

- (void)mapView:(MFMapView *)mapView didTapPOI:(MFPOI *)poi {
  if ([_mapDelegate respondsToSelector:@selector(mapView:didTapPOI:)]) {
    [_mapDelegate mapView:mapView didTapPOI:poi];
  }
}

- (void)mapView:(MFMapView *)mapView
    didTapPOIWithPlaceID:(NSString *)placeID
                    name:(NSString *)name
                location:(CLLocationCoordinate2D)location {
  if ([_mapDelegate respondsToSelector:@selector(mapView:didTapPOIWithPlaceID:name:location:)]) {
    [_mapDelegate mapView:mapView didTapPOIWithPlaceID:placeID name:name location:location];
  }
}

- (void)mapView:(MFMapView *)mapView didTapPlaceWithName:(NSString *)name location:(CLLocationCoordinate2D)location {
  if ([_mapDelegate respondsToSelector:@selector(mapView:didTapPlaceWithName:location:)]) {
    [_mapDelegate mapView:mapView didTapPlaceWithName:name location:location];
  }
}

- (void)mapView:(MFMapView *)mapView didTapMyLocation:(CLLocationCoordinate2D)location {
  if ([_mapDelegate respondsToSelector:@selector(mapView:didTapMyLocation:)]) {
    [_mapDelegate mapView:mapView didTapMyLocation:location];
  }
}

- (void)mapView:(MFMapView *)mapView didTapDirectionsRenderer:(MFDirectionsRenderer *)renderer routeIndex:(NSUInteger)routeIndex {
  if ([_mapDelegate respondsToSelector:@selector(mapView:didTapDirectionsRenderer:routeIndex:)]) {
    [_mapDelegate mapView:mapView didTapDirectionsRenderer:renderer routeIndex:routeIndex];
  }
}

- (BOOL)shouldChangeMapModeForMapView:(MFMapView *)mapView {
  if ([_mapDelegate respondsToSelector:@selector(shouldChangeMapModeForMapView:)]) {
    [_mapDelegate shouldChangeMapModeForMapView:mapView];
  }
  return NO;
}

- (void)mapview:(MFMapView *)mapView didBeginDraggingMarker:(MFMarker *)marker {
  if ([_mapDelegate respondsToSelector:@selector(mapview:didBeginDraggingMarker:)]) {
    [_mapDelegate mapview:mapView didBeginDraggingMarker:marker];
  }
}

- (void)mapview:(MFMapView *)mapView didEndDraggingMarker:(MFMarker *)marker {
  if ([_mapDelegate respondsToSelector:@selector(mapview:didEndDraggingMarker:)]) {
    [_mapDelegate mapview:mapView didEndDraggingMarker:marker];
  }
}

- (void)mapview:(MFMapView *)mapView didDragMarker:(MFMarker *)marker {
  if ([_mapDelegate respondsToSelector:@selector(mapview:didDragMarker:)]) {
    [_mapDelegate mapview:mapView didDragMarker:marker];
  }
}

- (BOOL)didTapMyLocationButtonForMapView:(MFMapView *)mapView {
  if ([_mapDelegate respondsToSelector:@selector(didTapMyLocationButtonForMapView:)]) {
    return [_mapDelegate didTapMyLocationButtonForMapView:mapView];
  }
  return NO;
}

#pragma mark Testing

- (NSUInteger)clusterRequestCount {
  return _clusterRequestCount;
}

#pragma mark Private

- (void)update {
  MFCameraPosition *camera = _mapView.camera;
  NSUInteger previousIntegralZoom = (NSUInteger)floorf(_previousCamera.zoom + 0.5f);
  NSUInteger currentIntegralZoom = (NSUInteger)floorf(camera.zoom + 0.5f);
  if (previousIntegralZoom != currentIntegralZoom) {
    [self requestCluster];
  } else {
    [_renderer update];
  }
}

- (void)requestCluster {
  __weak MFUClusterManager *weakSelf = self;
  ++_clusterRequestCount;
  NSUInteger requestNumber = _clusterRequestCount;
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMFUClusterWaitIntervalSeconds * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        MFUClusterManager *strongSelf = weakSelf;
        if (strongSelf == nil) {
          return;
        }

        // Ignore if there are newer requests.
        if (requestNumber != strongSelf->_clusterRequestCount) {
          return;
        }
        [strongSelf cluster];
      });
}

@end
