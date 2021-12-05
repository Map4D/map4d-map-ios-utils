#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFUSimpleClusterAlgorithm.h"

#import "MFUStaticCluster.h"
#import "MFUClusterItem.h"

static const NSUInteger kClusterCount = 10;

@implementation MFUSimpleClusterAlgorithm {
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
  NSMutableArray<id<MFUCluster>> *clusters =
      [[NSMutableArray alloc] initWithCapacity:kClusterCount];

  for (int i = 0; i < kClusterCount; ++i) {
    if (i >= _items.count) break;
    id<MFUClusterItem> item = _items[i];
    [clusters addObject:[[MFUStaticCluster alloc] initWithPosition:item.position]];
  }

  NSUInteger clusterIndex = 0;
  for (int i = kClusterCount; i < _items.count; ++i) {
    id<MFUClusterItem> item = _items[i];
    MFUStaticCluster *cluster = clusters[clusterIndex % kClusterCount];
    [cluster addItem:item];
    ++clusterIndex;
  }
  return clusters;
}

@end

