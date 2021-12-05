#import <Foundation/Foundation.h>

#import "MFUCluster.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Defines a common contract for a cluster renderer.
 */
@protocol MFUClusterRenderer<NSObject>

// Renders a list of clusters.
- (void)renderClusters:(NSArray<id<MFUCluster>> *)clusters;

// Notifies renderer that the viewport has changed and renderer needs to update.
// For example new clusters may become visible and need to be shown on map.
- (void)update;

@end

NS_ASSUME_NONNULL_END
