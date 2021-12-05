#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFUStaticCluster.h"

@implementation MFUStaticCluster {
  NSMutableArray<id<MFUClusterItem>> *_items;
}

- (instancetype)initWithPosition:(CLLocationCoordinate2D)position {
  if ((self = [super init])) {
    _items = [[NSMutableArray alloc] init];
    _position = position;
  }
  return self;
}

- (NSUInteger)count {
  return _items.count;
}

- (NSArray<id<MFUClusterItem>> *)items {
  return [_items copy];
}

- (void)addItem:(id<MFUClusterItem>)item {
  [_items addObject:item];
}

- (void)removeItem:(id<MFUClusterItem>)item {
  [_items removeObject:item];
}

@end
