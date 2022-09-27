#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFQTPointQuadTree.h"
#import "MFQTPointQuadTreeChild.h"

@implementation MFQTPointQuadTree {
  /**
   * The bounds of this PointQuadTree.
   */
  MFQTBounds bounds_;

  /**
   * The Quad Tree data structure.
   */
  MFQTPointQuadTreeChild *root_;

  /**
   * The number of items in this tree.
   */
  NSUInteger count_;
}

- (id)initWithBounds:(MFQTBounds)bounds {
  if (self = [super init]) {
    bounds_ = bounds;
    [self clear];
  }
  return self;
}

- (id)init {
  return [self initWithBounds:(MFQTBounds){-1, -1, 1, 1}];
}

- (BOOL)add:(id<MFQTPointQuadTreeItem>)item {
  if (item == nil) {
    // Item must not be nil.
    return NO;
  }

  MFQTPoint point = item.point;
  if (point.x > bounds_.maxX || point.x < bounds_.minX || point.y > bounds_.maxY ||
      point.y < bounds_.minY) {
    return NO;
  }

  [root_ add:item withOwnBounds:bounds_ atDepth:0];

  ++count_;

  return YES;
}

/**
 * Delete an item from this PointQuadTree
 *
 * @param item The item to delete.
 */
- (BOOL)remove:(id<MFQTPointQuadTreeItem>)item {
  MFQTPoint point = item.point;
  if (point.x > bounds_.maxX || point.x < bounds_.minX || point.y > bounds_.maxY ||
      point.y < bounds_.minY) {
    return NO;
  }

  BOOL removed = [root_ remove:item withOwnBounds:bounds_];

  if (removed) {
    --count_;
  }

  return removed;
}

/**
 * Delete all items from this PointQuadTree
 */
- (void)clear {
  root_ = [[MFQTPointQuadTreeChild alloc] init];
  count_ = 0;
}

/**
 * Retreive all items in this PointQuadTree within a bounding box.
 *
 * @param searchBounds The bounds of the search box.
 */
- (NSArray *)searchWithBounds:(MFQTBounds)searchBounds {
  NSMutableArray *results = [NSMutableArray array];
  [root_ searchWithBounds:searchBounds withOwnBounds:bounds_ results:results];
  return results;
}

- (NSUInteger)count {
  return count_;
}

@end
