#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFUGridBasedClusterAlgorithm.h"

#import "MFUGeometryUtils.h"

#import "MFUStaticCluster.h"
#import "MFUClusterItem.h"

// Grid cell dimension in pixels to keep clusters about 100 pixels apart on screen.
static const NSUInteger kMFUGridCellSizePoints = 100;

@implementation MFUGridBasedClusterAlgorithm {
  NSMutableArray<id<MFUClusterItem>> *_items;
}

- (instancetype)init {
  if ((self = [super init])) {
    _items = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)addItems:(NSArray<id<MFUClusterItem>> *)items {
  [_items addObjectsFromArray:items];
}

- (void)removeItem:(id<MFUClusterItem>)item {
  [_items removeObject:item];
}

- (void)clearItems {
  [_items removeAllObjects];
}

- (NSArray<id<MFUCluster>> *)clustersAtZoom:(float)zoom {
  NSMutableDictionary<NSNumber *, id<MFUCluster>> *clusters = [[NSMutableDictionary alloc] init];

  // Divide the whole map into a numCells x numCells grid and assign items to them.
  long numCells = (long)ceil(256 * pow(2, zoom) / kMFUGridCellSizePoints);
  for (id<MFUClusterItem> item in _items) {
    MFUMapPoint point = MFUProject(item.position);
    long col = (long)(numCells * (1.0 + point.x) / 2);  // point.x is in [-1, 1] range
    long row = (long)(numCells * (1.0 + point.y) / 2);  // point.y is in [-1, 1] range
    long index = numCells * row + col;
    NSNumber *cellKey = [NSNumber numberWithLong:index];
    MFUStaticCluster *cluster = clusters[cellKey];
    if (cluster == nil) {
      // Normalize cluster's centroid to center of the cell.
      MFUMapPoint point2 = {(double)(col + 0.5) * 2.0 / numCells - 1,
                            (double)(row + 0.5) * 2.0 / numCells - 1};
      CLLocationCoordinate2D position = MFUUnproject(point2);
      cluster = [[MFUStaticCluster alloc] initWithPosition:position];
      clusters[cellKey] = cluster;
    }
    [cluster addItem:item];
  }
  return [clusters allValues];
}

@end

