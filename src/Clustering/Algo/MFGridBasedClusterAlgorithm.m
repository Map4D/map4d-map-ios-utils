#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFGridBasedClusterAlgorithm.h"

#import "MFGeometryUtils.h"

#import "MFStaticCluster.h"
#import "MFClusterItem.h"

// Grid cell dimension in pixels to keep clusters about 100 pixels apart on screen.
static const NSUInteger kMFGridCellSizePoints = 100;

@implementation MFGridBasedClusterAlgorithm {
  NSMutableArray<id<MFClusterItem>> *_items;
}

- (instancetype)init {
  if ((self = [super init])) {
    _items = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)addItems:(NSArray<id<MFClusterItem>> *)items {
  [_items addObjectsFromArray:items];
}

- (void)removeItem:(id<MFClusterItem>)item {
  [_items removeObject:item];
}

- (void)clearItems {
  [_items removeAllObjects];
}

- (NSArray<id<MFCluster>> *)clustersAtZoom:(float)zoom {
  NSMutableDictionary<NSNumber *, id<MFCluster>> *clusters = [[NSMutableDictionary alloc] init];

  // Divide the whole map into a numCells x numCells grid and assign items to them.
  long numCells = (long)ceil(256 * pow(2, zoom) / kMFGridCellSizePoints);
  for (id<MFClusterItem> item in _items) {
    MFMapPoint point = MFProject(item.position);
    long col = (long)(numCells * (1.0 + point.x) / 2);  // point.x is in [-1, 1] range
    long row = (long)(numCells * (1.0 + point.y) / 2);  // point.y is in [-1, 1] range
    long index = numCells * row + col;
    NSNumber *cellKey = [NSNumber numberWithLong:index];
    MFStaticCluster *cluster = clusters[cellKey];
    if (cluster == nil) {
      // Normalize cluster's centroid to center of the cell.
      MFMapPoint point2 = {(double)(col + 0.5) * 2.0 / numCells - 1,
                            (double)(row + 0.5) * 2.0 / numCells - 1};
      CLLocationCoordinate2D position = MFUnproject(point2);
      cluster = [[MFStaticCluster alloc] initWithPosition:position];
      clusters[cellKey] = cluster;
    }
    [cluster addItem:item];
  }
  return [clusters allValues];
}

@end

