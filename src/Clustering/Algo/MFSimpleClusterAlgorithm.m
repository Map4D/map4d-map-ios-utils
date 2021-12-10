#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFSimpleClusterAlgorithm.h"

#import "MFStaticCluster.h"
#import "MFClusterItem.h"

static const NSUInteger kClusterCount = 10;

@implementation MFSimpleClusterAlgorithm {
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
  NSMutableArray<id<MFCluster>> *clusters =
      [[NSMutableArray alloc] initWithCapacity:kClusterCount];

  for (int i = 0; i < kClusterCount; ++i) {
    if (i >= _items.count) break;
    id<MFClusterItem> item = _items[i];
    [clusters addObject:[[MFStaticCluster alloc] initWithPosition:item.position]];
  }

  NSUInteger clusterIndex = 0;
  for (int i = kClusterCount; i < _items.count; ++i) {
    id<MFClusterItem> item = _items[i];
    MFStaticCluster *cluster = clusters[clusterIndex % kClusterCount];
    [cluster addItem:item];
    ++clusterIndex;
  }
  return clusters;
}

@end

