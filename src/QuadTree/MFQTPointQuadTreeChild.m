#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFQTPointQuadTreeChild.h"

static const unsigned kMaxElements = 64;
static const unsigned kMaxDepth = 30;

#include "MFQTBounds.h"

static MFQTPoint boundsMidpoint(MFQTBounds bounds) {
  return (MFQTPoint){(bounds.minX + bounds.maxX) / 2, (bounds.minY + bounds.maxY) / 2};
}

static MFQTBounds boundsTopRightChildQuadBounds(MFQTBounds parentBounds) {
  MFQTPoint midPoint = boundsMidpoint(parentBounds);
  double minX = midPoint.x;
  double minY = midPoint.y;
  double maxX = parentBounds.maxX;
  double maxY = parentBounds.maxY;
  return (MFQTBounds){minX, minY, maxX, maxY};
}

static MFQTBounds boundsTopLeftChildQuadBounds(MFQTBounds parentBounds) {
  MFQTPoint midPoint = boundsMidpoint(parentBounds);
  double minX = parentBounds.minX;
  double minY = midPoint.y;
  double maxX = midPoint.x;
  double maxY = parentBounds.maxY;
  return (MFQTBounds){minX, minY, maxX, maxY};
}

static MFQTBounds boundsBottomRightChildQuadBounds(MFQTBounds parentBounds) {
  MFQTPoint midPoint = boundsMidpoint(parentBounds);
  double minX = midPoint.x;
  double minY = parentBounds.minY;
  double maxX = parentBounds.maxX;
  double maxY = midPoint.y;
  return (MFQTBounds){minX, minY, maxX, maxY};
}

static MFQTBounds boundsBottomLeftChildQuadBounds(MFQTBounds parentBounds) {
  MFQTPoint midPoint = boundsMidpoint(parentBounds);
  double minX = parentBounds.minX;
  double minY = parentBounds.minY;
  double maxX = midPoint.x;
  double maxY = midPoint.y;
  return (MFQTBounds){minX, minY, maxX, maxY};
}

static BOOL boundsIntersectsBounds(MFQTBounds bounds1, MFQTBounds bounds2) {
  return (!(bounds1.maxY < bounds2.minY || bounds2.maxY < bounds1.minY) &&
          !(bounds1.maxX < bounds2.minX || bounds2.maxX < bounds1.minX));
}

@implementation MFQTPointQuadTreeChild {
  /** Top Right child quad. Nil until this node is split. */
  MFQTPointQuadTreeChild *topRight_;

  /** Top Left child quad. Nil until this node is split. */
  MFQTPointQuadTreeChild *topLeft_;

  /** Bottom Right child quad. Nil until this node is split. */
  MFQTPointQuadTreeChild *bottomRight_;

  /** Bottom Left child quad. Nil until this node is split. */
  MFQTPointQuadTreeChild *bottomLeft_;

  /**
   * Items in this PointQuadTree node, if this node has yet to be split. If we have items, children
   * will be nil, likewise, if we have children then items_ will be nil.
   */
  NSMutableArray *items_;
}

- (id)init {
  if (self = [super init]) {
    topRight_ = nil;
    topLeft_ = nil;
    bottomRight_ = nil;
    bottomLeft_ = nil;
    items_ = [NSMutableArray array];
  }
  return self;
}

- (void)add:(id<MFQTPointQuadTreeItem>)item
    withOwnBounds:(MFQTBounds)bounds
          atDepth:(NSUInteger)depth {
  if (item == nil) {
    // Note, this should not happen, as MFQTPointQuadTree's add method also does a nil check.
    [NSException raise:@"Invalid item argument" format:@"item must not be null"];
  }

  if (items_.count >= kMaxElements && depth < kMaxDepth) {
    [self splitWithOwnBounds:bounds atDepth:depth];
  }

  if (topRight_ != nil) {
    MFQTPoint itemPoint = item.point;
    MFQTPoint midPoint = boundsMidpoint(bounds);

    if (itemPoint.y > midPoint.y) {
      if (itemPoint.x > midPoint.x) {
        [topRight_ add:item withOwnBounds:boundsTopRightChildQuadBounds(bounds) atDepth:depth + 1];
      } else {
        [topLeft_ add:item withOwnBounds:boundsTopLeftChildQuadBounds(bounds) atDepth:depth + 1];
      }
    } else {
      if (itemPoint.x > midPoint.x) {
        [bottomRight_ add:item
            withOwnBounds:boundsBottomRightChildQuadBounds(bounds)
                  atDepth:depth + 1];
      } else {
        [bottomLeft_ add:item
            withOwnBounds:boundsBottomLeftChildQuadBounds(bounds)
                  atDepth:depth + 1];
      }
    }
  } else {
    [items_ addObject:item];
  }
}

- (void)splitWithOwnBounds:(MFQTBounds)ownBounds atDepth:(NSUInteger)depth {
  assert(items_ != nil);

  topRight_ = [[MFQTPointQuadTreeChild alloc] init];
  topLeft_ = [[MFQTPointQuadTreeChild alloc] init];
  bottomRight_ = [[MFQTPointQuadTreeChild alloc] init];
  bottomLeft_ = [[MFQTPointQuadTreeChild alloc] init];

  NSArray *items = items_;
  items_ = nil;

  for (id<MFQTPointQuadTreeItem> item in items) {
    [self add:item withOwnBounds:ownBounds atDepth:depth];
  }
}

- (BOOL)remove:(id<MFQTPointQuadTreeItem>)item withOwnBounds:(MFQTBounds)bounds {
  if (topRight_ != nil) {
    MFQTPoint itemPoint = item.point;
    MFQTPoint midPoint = boundsMidpoint(bounds);

    if (itemPoint.y > midPoint.y) {
      if (itemPoint.x > midPoint.x) {
        return [topRight_ remove:item withOwnBounds:boundsTopRightChildQuadBounds(bounds)];
      } else {
        return [topLeft_ remove:item withOwnBounds:boundsTopLeftChildQuadBounds(bounds)];
      }
    } else {
      if (itemPoint.x > midPoint.x) {
        return [bottomRight_ remove:item withOwnBounds:boundsBottomRightChildQuadBounds(bounds)];
      } else {
        return [bottomLeft_ remove:item withOwnBounds:boundsBottomLeftChildQuadBounds(bounds)];
      }
    }
  }

  NSUInteger index = [items_ indexOfObject:item];
  if (index != NSNotFound) {
    [items_ removeObjectAtIndex:index];
    return YES;
  } else {
    return NO;
  }
}

- (void)searchWithBounds:(MFQTBounds)searchBounds
           withOwnBounds:(MFQTBounds)ownBounds
                 results:(NSMutableArray *)accumulator {
  if (topRight_ != nil) {
    MFQTBounds topRightBounds = boundsTopRightChildQuadBounds(ownBounds);
    MFQTBounds topLeftBounds = boundsTopLeftChildQuadBounds(ownBounds);
    MFQTBounds bottomRightBounds = boundsBottomRightChildQuadBounds(ownBounds);
    MFQTBounds bottomLeftBounds = boundsBottomLeftChildQuadBounds(ownBounds);

    if (boundsIntersectsBounds(topRightBounds, searchBounds)) {
      [topRight_ searchWithBounds:searchBounds withOwnBounds:topRightBounds results:accumulator];
    }
    if (boundsIntersectsBounds(topLeftBounds, searchBounds)) {
      [topLeft_ searchWithBounds:searchBounds withOwnBounds:topLeftBounds results:accumulator];
    }
    if (boundsIntersectsBounds(bottomRightBounds, searchBounds)) {
      [bottomRight_ searchWithBounds:searchBounds
                       withOwnBounds:bottomRightBounds
                             results:accumulator];
    }
    if (boundsIntersectsBounds(bottomLeftBounds, searchBounds)) {
      [bottomLeft_ searchWithBounds:searchBounds
                      withOwnBounds:bottomLeftBounds
                            results:accumulator];
    }
  } else {
    for (id<MFQTPointQuadTreeItem> item in items_) {
      MFQTPoint point = item.point;
      if (point.x <= searchBounds.maxX && point.x >= searchBounds.minX &&
          point.y <= searchBounds.maxY && point.y >= searchBounds.minY) {
        [accumulator addObject:item];
      }
    }
  }
}

@end
