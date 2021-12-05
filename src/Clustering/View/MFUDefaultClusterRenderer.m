#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import <Map4dMap/Map4dMap.h>

#import "MFUDefaultClusterRenderer.h"
#import "MFUClusterIconGenerator.h"
#import "MFUWrappingDictionaryKey.h"

// Clusters smaller than this threshold will be expanded.
static const NSUInteger kMFUMinClusterSize = 4;

// At zooms above this level, clusters will be expanded.
// This is to prevent cases where items are so close to each other than they are always grouped.
static const float kMFUMaxClusterZoom = 20;

// Animation duration for marker splitting/merging effects.
static const double kMFUAnimationDuration = 0.5;  // seconds.

@implementation MFUDefaultClusterRenderer {
  // Map view to render clusters on.
  __weak MFMapView *_mapView;

  // Collection of markers added to the map.
  NSMutableArray<MFMarker *> *_mutableMarkers;

  // Icon generator used to create cluster icon.
  id<MFUClusterIconGenerator> _clusterIconGenerator;

  // Current clusters being rendered.
  NSArray<id<MFUCluster>> *_clusters;

  // Tracks clusters that have been rendered to the map.
  NSMutableSet *_renderedClusters;

  // Tracks cluster items that have been rendered to the map.
  NSMutableSet *_renderedClusterItems;

  // Stores previous zoom level to determine zooming direction (in/out).
  float _previousZoom;

  // Lookup map from cluster item to an old cluster.
  NSMutableDictionary<MFUWrappingDictionaryKey *, id<MFUCluster>> *_itemToOldClusterMap;

  // Lookup map from cluster item to a new cluster.
  NSMutableDictionary<MFUWrappingDictionaryKey *, id<MFUCluster>> *_itemToNewClusterMap;
}

- (instancetype)initWithMapView:(MFMapView *)mapView
           clusterIconGenerator:(id<MFUClusterIconGenerator>)iconGenerator {
  if ((self = [super init])) {
    _mapView = mapView;
    _mutableMarkers = [[NSMutableArray<MFMarker *> alloc] init];
    _clusterIconGenerator = iconGenerator;
    _renderedClusters = [[NSMutableSet alloc] init];
    _renderedClusterItems = [[NSMutableSet alloc] init];
    _animatesClusters = YES;
    _minimumClusterSize = kMFUMinClusterSize;
    _maximumClusterZoom = kMFUMaxClusterZoom;
    _animationDuration = kMFUAnimationDuration;

    _zIndex = 1;
  }
  return self;
}

- (void)dealloc {
  [self clear];
}

- (BOOL)shouldRenderAsCluster:(id<MFUCluster>)cluster atZoom:(float)zoom {
  return cluster.count >= _minimumClusterSize && zoom <= _maximumClusterZoom;
}

#pragma mark MFUClusterRenderer

- (void)renderClusters:(NSArray<id<MFUCluster>> *)clusters {
  [_renderedClusters removeAllObjects];
  [_renderedClusterItems removeAllObjects];

  if (_animatesClusters) {
    [self renderAnimatedClusters:clusters];
  } else {
    // No animation, just remove existing markers and add new ones.
    _clusters = [clusters copy];
    [self clearMarkers:_mutableMarkers];
    _mutableMarkers = [[NSMutableArray<MFMarker *> alloc] init];
    [self addOrUpdateClusters:clusters animated:NO];
  }
}

- (void)renderAnimatedClusters:(NSArray<id<MFUCluster>> *)clusters {
  float zoom = _mapView.camera.zoom;
  BOOL isZoomingIn = zoom > _previousZoom;

  [self prepareClustersForAnimation:clusters isZoomingIn:isZoomingIn];

  _previousZoom = zoom;

  _clusters = [clusters copy];

  NSMutableArray<MFMarker *> *existingMarkers = _mutableMarkers;
  _mutableMarkers = [[NSMutableArray<MFMarker *> alloc] init];

  [self addOrUpdateClusters:clusters animated:isZoomingIn];
  
  // If the marker was re-added, remove from existingMarkers which will be cleared
  for (MFMarker *visibleMarker in _mutableMarkers) {
    [existingMarkers removeObject:visibleMarker];
  }

  if (isZoomingIn) {
    [self clearMarkers:existingMarkers];
  } else {
    [self clearMarkersAnimated:existingMarkers];
  }
}

- (void)clearMarkersAnimated:(NSArray<MFMarker *> *)markers {
  // Remove existing markers: animate to nearest new cluster.
  MFCoordinateBounds *visibleBounds = [_mapView getBounds];

  for (MFMarker *marker in markers) {
    // If the marker for the attached userData has just been added, do not perform animation.
    if ([_renderedClusterItems containsObject:marker.userData]) {
      marker.map = nil;
      continue;
    }
    // If the marker is outside the visible view port, do not perform animation.
    if (![visibleBounds contains:marker.position]) {
      marker.map = nil;
      continue;
    }

    // Find a candidate cluster to animate to.
    id<MFUCluster> toCluster = nil;
    if ([marker.userData conformsToProtocol:@protocol(MFUCluster)]) {
      id<MFUCluster> cluster = marker.userData;
      toCluster = [self overlappingClusterForCluster:cluster itemMap:_itemToNewClusterMap];
    } else {
      MFUWrappingDictionaryKey *key =
          [[MFUWrappingDictionaryKey alloc] initWithObject:marker.userData];
      toCluster = [_itemToNewClusterMap objectForKey:key];
    }
    // If there is not near by cluster to animate to, do not perform animation.
    if (toCluster == nil) {
      marker.map = nil;
      continue;
    }

    // All is good, perform the animation.
    [CATransaction begin];
    [CATransaction setAnimationDuration:_animationDuration];
    CLLocationCoordinate2D toPosition = toCluster.position;
    marker.position = toPosition;
    [CATransaction commit];
  }

  // Clears existing markers after animation has presumably ended.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, _animationDuration * NSEC_PER_SEC),
                 dispatch_get_main_queue(), ^{
                   [self clearMarkers:markers];
                 });
}

// Called when camera is changed to reevaluate if new clusters need to be displayed because
// they become visible.
- (void)update {
  [self addOrUpdateClusters:_clusters animated:NO];
}

- (NSArray<MFMarker *> *)markers {
  return [_mutableMarkers copy];
}

#pragma mark Private

// Builds lookup map for item to old clusters, new clusters.
- (void)prepareClustersForAnimation:(NSArray<id<MFUCluster>> *)newClusters
                        isZoomingIn:(BOOL)isZoomingIn {
  float zoom = _mapView.camera.zoom;

  if (isZoomingIn) {
    _itemToOldClusterMap =
        [[NSMutableDictionary<MFUWrappingDictionaryKey *, id<MFUCluster>> alloc] init];
    for (id<MFUCluster> cluster in _clusters) {
      if (![self shouldRenderAsCluster:cluster atZoom:zoom]
          && ![self shouldRenderAsCluster:cluster atZoom:_previousZoom]) {
        continue;
      }
      for (id<MFUClusterItem> clusterItem in cluster.items) {
        MFUWrappingDictionaryKey *key =
            [[MFUWrappingDictionaryKey alloc] initWithObject:clusterItem];
        [_itemToOldClusterMap setObject:cluster forKey:key];
      }
    }
    _itemToNewClusterMap = nil;
  } else {
    _itemToOldClusterMap = nil;
    _itemToNewClusterMap =
        [[NSMutableDictionary<MFUWrappingDictionaryKey *, id<MFUCluster>> alloc] init];
    for (id<MFUCluster> cluster in newClusters) {
      if (![self shouldRenderAsCluster:cluster atZoom:zoom]) continue;
      for (id<MFUClusterItem> clusterItem in cluster.items) {
        MFUWrappingDictionaryKey *key =
            [[MFUWrappingDictionaryKey alloc] initWithObject:clusterItem];
        [_itemToNewClusterMap setObject:cluster forKey:key];
      }
    }
  }
}

// Goes through each cluster |clusters| and add a marker for it if it is:
// - inside the visible region of the camera.
// - not yet already added.
- (void)addOrUpdateClusters:(NSArray<id<MFUCluster>> *)clusters animated:(BOOL)animated {
  MFCoordinateBounds *visibleBounds = [_mapView getBounds];

  for (id<MFUCluster> cluster in clusters) {
    if ([_renderedClusters containsObject:cluster]) continue;

    BOOL shouldShowCluster = [visibleBounds contains:cluster.position];
    BOOL shouldRenderAsCluster = [self shouldRenderAsCluster:cluster atZoom: _mapView.camera.zoom];

    if (!shouldShowCluster) {
      for (id<MFUClusterItem> item in cluster.items) {
        if (!shouldRenderAsCluster && [visibleBounds contains:item.position]) {
          shouldShowCluster = YES;
          break;
        }
        if (animated) {
          MFUWrappingDictionaryKey *key = [[MFUWrappingDictionaryKey alloc] initWithObject:item];
          id<MFUCluster> oldCluster = [_itemToOldClusterMap objectForKey:key];
          if (oldCluster != nil && [visibleBounds contains:oldCluster.position]) {
            shouldShowCluster = YES;
            break;
          }
        }
      }
    }
    if (shouldShowCluster) {
      [self renderCluster:cluster animated:animated];
    }
  }
}

- (void)renderCluster:(id<MFUCluster>)cluster animated:(BOOL)animated {
  float zoom = _mapView.camera.zoom;
  if ([self shouldRenderAsCluster:cluster atZoom:zoom]) {
    CLLocationCoordinate2D fromPosition = kCLLocationCoordinate2DInvalid;
    if (animated) {
      id<MFUCluster> fromCluster =
          [self overlappingClusterForCluster:cluster itemMap:_itemToOldClusterMap];
      animated = fromCluster != nil;
      fromPosition = fromCluster.position;
    }

    UIImage *icon = [_clusterIconGenerator iconForSize:cluster.count];
    MFMarker *marker = [self markerWithPosition:cluster.position
                                            from:fromPosition
                                        userData:cluster
                                     clusterIcon:icon
                                        animated:animated];
    [_mutableMarkers addObject:marker];
  } else {
    for (id<MFUClusterItem> item in cluster.items) {
      MFMarker *marker;
      if ([item class] == [MFMarker class]) {
        marker = (MFMarker<MFUClusterItem> *)item;
        marker.map = _mapView;
      } else {
        CLLocationCoordinate2D fromPosition = kCLLocationCoordinate2DInvalid;
        BOOL shouldAnimate = animated;
        if (shouldAnimate) {
          MFUWrappingDictionaryKey *key = [[MFUWrappingDictionaryKey alloc] initWithObject:item];
          id<MFUCluster> fromCluster = [_itemToOldClusterMap objectForKey:key];
          shouldAnimate = fromCluster != nil;
          fromPosition = fromCluster.position;
        }
        marker = [self markerWithPosition:item.position
                                     from:fromPosition
                                 userData:item
                              clusterIcon:nil
                                 animated:shouldAnimate];
        if ([item respondsToSelector:@selector(title)]) {
            marker.title = item.title;
        }
        if ([item respondsToSelector:@selector(snippet)]) {
            marker.snippet = item.snippet;
        }
      }
      [_mutableMarkers addObject:marker];
      [_renderedClusterItems addObject:item];
    }
  }
  [_renderedClusters addObject:cluster];
}

- (MFMarker *)markerForObject:(id)object {
  MFMarker *marker;
  if ([_delegate respondsToSelector:@selector(renderer:markerForObject:)]) {
    marker = [_delegate renderer:self markerForObject:object];
  }
  return marker ?: [[MFMarker alloc] init];
}

// Returns a marker at final position of |position| with attached |userData|.
// If animated is YES, animates from the closest point from |points|.
- (MFMarker *)markerWithPosition:(CLLocationCoordinate2D)position
                             from:(CLLocationCoordinate2D)from
                         userData:(id)userData
                      clusterIcon:(UIImage *)clusterIcon
                         animated:(BOOL)animated {
  MFMarker *marker = [self markerForObject:userData];
  CLLocationCoordinate2D initialPosition = animated ? from : position;
  marker.position = initialPosition;
  marker.userData = userData;
  if (clusterIcon != nil) {
    marker.icon = clusterIcon;
    marker.groundAnchor = CGPointMake(0.5, 0.5);
  }
  marker.zIndex = _zIndex;

  if ([_delegate respondsToSelector:@selector(renderer:willRenderMarker:)]) {
    [_delegate renderer:self willRenderMarker:marker];
  }
  marker.map = _mapView;

  if (animated) {
    [CATransaction begin];
    [CATransaction setAnimationDuration:_animationDuration];
    marker.position = position;
    [CATransaction commit];
  }

  if ([_delegate respondsToSelector:@selector(renderer:didRenderMarker:)]) {
    [_delegate renderer:self didRenderMarker:marker];
  }
  return marker;
}

// Returns clusters which should be rendered and is inside the camera visible region.
- (NSArray<id<MFUCluster>> *)visibleClustersFromClusters:(NSArray<id<MFUCluster>> *)clusters {
  NSMutableArray *visibleClusters = [[NSMutableArray alloc] init];
  float zoom = _mapView.camera.zoom;
  MFCoordinateBounds *visibleBounds = [_mapView getBounds];
  for (id<MFUCluster> cluster in clusters) {
    if (![visibleBounds contains:cluster.position]) continue;
    if (![self shouldRenderAsCluster:cluster atZoom:zoom]) continue;
    [visibleClusters addObject:cluster];
  }
  return visibleClusters;
}

// Returns the first cluster in |itemMap| that shares a common item with the input |cluster|.
// Used for heuristically finding candidate cluster to animate to/from.
- (id<MFUCluster>)overlappingClusterForCluster:
    (id<MFUCluster>)cluster
        itemMap:(NSDictionary<MFUWrappingDictionaryKey *, id<MFUCluster>> *)itemMap {
  id<MFUCluster> found = nil;
  for (id<MFUClusterItem> item in cluster.items) {
    MFUWrappingDictionaryKey *key = [[MFUWrappingDictionaryKey alloc] initWithObject:item];
    id<MFUCluster> candidate = [itemMap objectForKey:key];
    if (candidate != nil) {
      found = candidate;
      break;
    }
  }
  return found;
}

// Removes all existing markers from the attached map.
- (void)clear {
  [self clearMarkers:_mutableMarkers];
  [_mutableMarkers removeAllObjects];
  [_renderedClusters removeAllObjects];
  [_renderedClusterItems removeAllObjects];
  [_itemToNewClusterMap removeAllObjects];
  [_itemToOldClusterMap removeAllObjects];
  _clusters = nil;
}

- (void)clearMarkers:(NSArray<MFMarker *> *)markers {
  for (MFMarker *marker in markers) {
    if ([marker.userData conformsToProtocol:@protocol(MFUCluster)]) {
      marker.userData = nil;
    }
    marker.map = nil;
  }
}

@end
