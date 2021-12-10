#import <Foundation/Foundation.h>

#import "MFClusterAlgorithm.h"

/**
 * A simple clustering algorithm with O(nlog n) performance. Resulting clusters are not
 * hierarchical.
 * High level algorithm:
 * 1. Iterate over items in the order they were added (candidate clusters).
 * 2. Create a cluster with the center of the item.
 * 3. Add all items that are within a certain distance to the cluster.
 * 4. Move any items out of an existing cluster if they are closer to another cluster.
 * 5. Remove those items from the list of candidate clusters.
 * Clusters have the center of the first element (not the centroid of the items within it).
 */
@interface MFNonHierarchicalDistanceBasedAlgorithm : NSObject<MFClusterAlgorithm>

/**
 * Initializes this MFNonHierarchicalDistanceBasedAlgorithm with clusterDistancePoints for
 * the distance it uses to cluster items (default is 100).
 */
- (instancetype)initWithClusterDistancePoints:(NSUInteger)clusterDistancePoints;

@end
