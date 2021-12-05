#import <Foundation/Foundation.h>

#import "MFUCluster.h"
#import "MFUClusterItem.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Generic protocol for arranging cluster items into groups.
 */
@protocol MFUClusterAlgorithm<NSObject>

- (void)addItems:(NSArray<id<MFUClusterItem>> *)items;

/**
 * Removes an item.
 */
- (void)removeItem:(id<MFUClusterItem>)item;

/**
 * Clears all items.
 */
- (void)clearItems;

/**
 * Returns the set of clusters of the added items.
 */
- (NSArray<id<MFUCluster>> *)clustersAtZoom:(float)zoom;

@end

NS_ASSUME_NONNULL_END
