#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFNonHierarchicalDistanceBasedAlgorithm.h"

#import "MFGeometryUtils.h"

#import "MFStaticCluster.h"
#import "MFClusterItem.h"
#import "MFWrappingDictionaryKey.h"
#import "MFQTPointQuadTree.h"

static const NSUInteger kMFDefaultClusterDistancePoints = 100;
static const double kMFMapPointWidth = 2.0;  // MapPoint is in a [-1,1]x[-1,1] space.

#pragma mark Utilities Classes

@interface MFClusterItemQuadItem : NSObject<MFQTPointQuadTreeItem>

@property(nonatomic, readonly) id<MFClusterItem> clusterItem;

- (instancetype)initWithClusterItem:(id<MFClusterItem>)clusterItem;

@end

@implementation MFClusterItemQuadItem {
  id<MFClusterItem> _clusterItem;
  MFQTPoint _clusterItemPoint;
}

- (instancetype)initWithClusterItem:(id<MFClusterItem>)clusterItem {
  if ((self = [super init])) {
    _clusterItem = clusterItem;
    MFMapPoint point = MFProject(clusterItem.position);
    _clusterItemPoint.x = point.x;
    _clusterItemPoint.y = point.y;
  }
  return self;
}

- (MFQTPoint)point {
  return _clusterItemPoint;
}

// Forwards hash to clusterItem.
- (NSUInteger)hash {
  return [_clusterItem hash];
}

// Forwards isEqual to clusterItem.
- (BOOL)isEqual:(id)object {
  if (self == object) return YES;

  if ([object class] != [self class]) return NO;

  MFClusterItemQuadItem *other = (MFClusterItemQuadItem *)object;
  return [_clusterItem isEqual:other->_clusterItem];
}

@end

#pragma mark MFNonHierarchicalDistanceBasedAlgorithm

@implementation MFNonHierarchicalDistanceBasedAlgorithm {
  NSMutableArray<id<MFClusterItem>> *_items;
  MFQTPointQuadTree *_quadTree;
  NSUInteger _clusterDistancePoints;
}

- (instancetype)init {
  return [self initWithClusterDistancePoints:kMFDefaultClusterDistancePoints];
}

- (instancetype)initWithClusterDistancePoints:(NSUInteger)clusterDistancePoints {
    if ((self = [super init])) {
      _items = [[NSMutableArray alloc] init];
      MFQTBounds bounds = {-1, -1, 1, 1};
      _quadTree = [[MFQTPointQuadTree alloc] initWithBounds:bounds];
      _clusterDistancePoints = clusterDistancePoints;
    }
    return self;
}

- (void)addItems:(NSArray<id<MFClusterItem>> *)items {
  [_items addObjectsFromArray:items];
  for (id<MFClusterItem> item in items) {
    MFClusterItemQuadItem *quadItem = [[MFClusterItemQuadItem alloc] initWithClusterItem:item];
    [_quadTree add:quadItem];
  }
}

/**
 * Removes an item.
 */
- (void)removeItem:(id<MFClusterItem>)item {
  [_items removeObject:item];

  MFClusterItemQuadItem *quadItem = [[MFClusterItemQuadItem alloc] initWithClusterItem:item];
  // This should remove the corresponding quad item since MFClusterItemQuadItem forwards its hash
  // and isEqual to the underlying item.
  [_quadTree remove:quadItem];
}

/**
 * Clears all items.
 */
- (void)clearItems {
  [_items removeAllObjects];
  [_quadTree clear];
}

/**
 * Returns the set of clusters of the added items.
 */
- (NSArray<id<MFCluster>> *)clustersAtZoom:(float)zoom {
  NSMutableArray<id<MFCluster>> *clusters = [[NSMutableArray alloc] init];
  NSMutableDictionary<MFWrappingDictionaryKey *, id<MFCluster>> *itemToClusterMap =
      [[NSMutableDictionary alloc] init];
  NSMutableDictionary<MFWrappingDictionaryKey *, NSNumber *> *itemToClusterDistanceMap =
      [[NSMutableDictionary alloc] init];
  NSMutableSet<id<MFClusterItem>> *processedItems = [[NSMutableSet alloc] init];

  for (id<MFClusterItem> item in _items) {
    if ([processedItems containsObject:item]) continue;

    MFStaticCluster *cluster = [[MFStaticCluster alloc] initWithPosition:item.position];

    MFMapPoint point = MFProject(item.position);

    // Query for items within a fixed point distance from the current item to make up a cluster
    // around it.
    double radius = _clusterDistancePoints * kMFMapPointWidth / pow(2.0, zoom + 8.0);
    MFQTBounds bounds = {point.x - radius, point.y - radius, point.x + radius, point.y + radius};
    NSArray *nearbyItems = [_quadTree searchWithBounds:bounds];
    for (MFClusterItemQuadItem *quadItem in nearbyItems) {
      id<MFClusterItem> nearbyItem = quadItem.clusterItem;
      [processedItems addObject:nearbyItem];
      MFMapPoint nearbyItemPoint = MFProject(nearbyItem.position);
      MFWrappingDictionaryKey *key = [[MFWrappingDictionaryKey alloc] initWithObject:nearbyItem];

      NSNumber *existingDistance = [itemToClusterDistanceMap objectForKey:key];
      double distanceSquared = [self distanceSquaredBetweenPointA:point andPointB:nearbyItemPoint];
      if (existingDistance != nil) {
        if ([existingDistance doubleValue] < distanceSquared) {
          // Already belongs to a closer cluster.
          continue;
        }
        MFStaticCluster *existingCluster = [itemToClusterMap objectForKey:key];
        [existingCluster removeItem:nearbyItem];
      }
      NSNumber *number = [NSNumber numberWithDouble:distanceSquared];
      [itemToClusterDistanceMap setObject:number forKey:key];
      [itemToClusterMap setObject:cluster forKey:key];
      [cluster addItem:nearbyItem];
    }
    [clusters addObject:cluster];
  }
  NSAssert(itemToClusterDistanceMap.count == _items.count,
           @"All items should be mapped to a distance");
  NSAssert(itemToClusterMap.count == _items.count,
           @"All items should be mapped to a cluster");

#if DEBUG
  NSUInteger totalCount = 0;
  for (id<MFCluster> cluster in clusters) {
    totalCount += cluster.count;
  }
  NSAssert(_items.count == totalCount, @"All clusters combined should make up original item set");
#endif
  return clusters;
}

#pragma mark Private

- (double)distanceSquaredBetweenPointA:(MFMapPoint)pointA andPointB:(MFMapPoint)pointB {
  double deltaX = pointA.x - pointB.x;
  double deltaY = pointA.y - pointB.y;
  return deltaX * deltaX + deltaY * deltaY;
}

@end

