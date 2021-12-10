#import <Foundation/Foundation.h>

#import "MFCluster.h"
#import "MFClusterItem.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Generic protocol for arranging cluster items into groups.
 */
@protocol MFClusterAlgorithm<NSObject>

- (void)addItems:(NSArray<id<MFClusterItem>> *)items;

/**
 * Removes an item.
 */
- (void)removeItem:(id<MFClusterItem>)item;

/**
 * Clears all items.
 */
- (void)clearItems;

/**
 * Returns the set of clusters of the added items.
 */
- (NSArray<id<MFCluster>> *)clustersAtZoom:(float)zoom;

@end

NS_ASSUME_NONNULL_END
