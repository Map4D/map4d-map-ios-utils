#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFUNonHierarchicalDistanceBasedAlgorithm.h"

#import "MFUGeometryUtils.h"

#import "MFUStaticCluster.h"
#import "MFUClusterItem.h"
#import "MFUWrappingDictionaryKey.h"
#import "GQTPointQuadTree.h"

static const NSUInteger kMFUDefaultClusterDistancePoints = 100;
static const double kMFUMapPointWidth = 2.0;  // MapPoint is in a [-1,1]x[-1,1] space.

#pragma mark Utilities Classes

@interface MFUClusterItemQuadItem : NSObject<GQTPointQuadTreeItem>

@property(nonatomic, readonly) id<MFUClusterItem> clusterItem;

- (instancetype)initWithClusterItem:(id<MFUClusterItem>)clusterItem;

@end

@implementation MFUClusterItemQuadItem {
  id<MFUClusterItem> _clusterItem;
  GQTPoint _clusterItemPoint;
}

- (instancetype)initWithClusterItem:(id<MFUClusterItem>)clusterItem {
  if ((self = [super init])) {
    _clusterItem = clusterItem;
    MFUMapPoint point = MFUProject(clusterItem.position);
    _clusterItemPoint.x = point.x;
    _clusterItemPoint.y = point.y;
  }
  return self;
}

- (GQTPoint)point {
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

  MFUClusterItemQuadItem *other = (MFUClusterItemQuadItem *)object;
  return [_clusterItem isEqual:other->_clusterItem];
}

@end

#pragma mark MFUNonHierarchicalDistanceBasedAlgorithm

@implementation MFUNonHierarchicalDistanceBasedAlgorithm {
  NSMutableArray<id<MFUClusterItem>> *_items;
  GQTPointQuadTree *_quadTree;
  NSUInteger _clusterDistancePoints;
}

- (instancetype)init {
  return [self initWithClusterDistancePoints:kMFUDefaultClusterDistancePoints];
}

- (instancetype)initWithClusterDistancePoints:(NSUInteger)clusterDistancePoints {
    if ((self = [super init])) {
      _items = [[NSMutableArray alloc] init];
      GQTBounds bounds = {-1, -1, 1, 1};
      _quadTree = [[GQTPointQuadTree alloc] initWithBounds:bounds];
      _clusterDistancePoints = clusterDistancePoints;
    }
    return self;
}

- (void)addItems:(NSArray<id<MFUClusterItem>> *)items {
  [_items addObjectsFromArray:items];
  for (id<MFUClusterItem> item in items) {
    MFUClusterItemQuadItem *quadItem = [[MFUClusterItemQuadItem alloc] initWithClusterItem:item];
    [_quadTree add:quadItem];
  }
}

/**
 * Removes an item.
 */
- (void)removeItem:(id<MFUClusterItem>)item {
  [_items removeObject:item];

  MFUClusterItemQuadItem *quadItem = [[MFUClusterItemQuadItem alloc] initWithClusterItem:item];
  // This should remove the corresponding quad item since MFUClusterItemQuadItem forwards its hash
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
- (NSArray<id<MFUCluster>> *)clustersAtZoom:(float)zoom {
  NSMutableArray<id<MFUCluster>> *clusters = [[NSMutableArray alloc] init];
  NSMutableDictionary<MFUWrappingDictionaryKey *, id<MFUCluster>> *itemToClusterMap =
      [[NSMutableDictionary alloc] init];
  NSMutableDictionary<MFUWrappingDictionaryKey *, NSNumber *> *itemToClusterDistanceMap =
      [[NSMutableDictionary alloc] init];
  NSMutableSet<id<MFUClusterItem>> *processedItems = [[NSMutableSet alloc] init];

  for (id<MFUClusterItem> item in _items) {
    if ([processedItems containsObject:item]) continue;

    MFUStaticCluster *cluster = [[MFUStaticCluster alloc] initWithPosition:item.position];

    MFUMapPoint point = MFUProject(item.position);

    // Query for items within a fixed point distance from the current item to make up a cluster
    // around it.
    double radius = _clusterDistancePoints * kMFUMapPointWidth / pow(2.0, zoom + 8.0);
    GQTBounds bounds = {point.x - radius, point.y - radius, point.x + radius, point.y + radius};
    NSArray *nearbyItems = [_quadTree searchWithBounds:bounds];
    for (MFUClusterItemQuadItem *quadItem in nearbyItems) {
      id<MFUClusterItem> nearbyItem = quadItem.clusterItem;
      [processedItems addObject:nearbyItem];
      MFUMapPoint nearbyItemPoint = MFUProject(nearbyItem.position);
      MFUWrappingDictionaryKey *key = [[MFUWrappingDictionaryKey alloc] initWithObject:nearbyItem];

      NSNumber *existingDistance = [itemToClusterDistanceMap objectForKey:key];
      double distanceSquared = [self distanceSquaredBetweenPointA:point andPointB:nearbyItemPoint];
      if (existingDistance != nil) {
        if ([existingDistance doubleValue] < distanceSquared) {
          // Already belongs to a closer cluster.
          continue;
        }
        MFUStaticCluster *existingCluster = [itemToClusterMap objectForKey:key];
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
  for (id<MFUCluster> cluster in clusters) {
    totalCount += cluster.count;
  }
  NSAssert(_items.count == totalCount, @"All clusters combined should make up original item set");
#endif
  return clusters;
}

#pragma mark Private

- (double)distanceSquaredBetweenPointA:(MFUMapPoint)pointA andPointB:(MFUMapPoint)pointB {
  double deltaX = pointA.x - pointB.x;
  double deltaY = pointA.y - pointB.y;
  return deltaX * deltaX + deltaY * deltaY;
}

@end

