#import <Foundation/Foundation.h>

#import "MFUClusterRenderer.h"

NS_ASSUME_NONNULL_BEGIN

@class MFMapView;
@class MFMarker;

@protocol MFUCluster;
@protocol MFUClusterIconGenerator;
@protocol MFUClusterRenderer;

/**
 * Delegate for id<MFUClusterRenderer> to provide extra functionality to the default
 * renderer.
 */
@protocol MFUClusterRendererDelegate<NSObject>

@optional

/**
 * Returns a marker for an |object|. The |object| can be either an id<MFUCluster>
 * or an id<MFUClusterItem>. Use this delegate to control of the life cycle of
 * the marker. Any properties set on the returned marker will be honoured except
 * for: .position, .icon, .groundAnchor, .zIndex and .userData. To customize
 * these properties use renderer:willRenderMarker.
 * Note that changing a marker's position is not recommended because it will
 * interfere with the marker animation.
 */
- (nullable MFMarker *)renderer:(id<MFUClusterRenderer>)renderer markerForObject:(id)object;

/**
 * Raised when a marker (for a cluster or an item) is about to be added to the map.
 * Use the marker.userData property to check whether it is a cluster marker or an
 * item marker.
 */
- (void)renderer:(id<MFUClusterRenderer>)renderer willRenderMarker:(MFMarker *)marker;

/**
 * Raised when a marker (for a cluster or an item) has just been added to the map
 * and animation has been added.
 * Use the marker.userData property to check whether it is a cluster marker or an
 * item marker.
 */
- (void)renderer:(id<MFUClusterRenderer>)renderer didRenderMarker:(MFMarker *)marker;

@end

/**
 * Default cluster renderer which shows clusters as markers with specialized icons.
 * There is logic to decide whether to expand a cluster or not depending on the number of
 * items or the zoom level.
 * There is also some performance optimization where only clusters within the visisble
 * region are shown.
 */
@interface MFUDefaultClusterRenderer : NSObject<MFUClusterRenderer>

/**
 * Creates a new cluster renderer with a given map view and icon generator.
 *
 * @param mapView The map view to use.
 * @param iconGenerator The icon generator to use. Can be subclassed if required.
 */
- (instancetype)initWithMapView:(MFMapView *)mapView
           clusterIconGenerator:(id<MFUClusterIconGenerator>)iconGenerator;

/**
 * Animates the clusters to achieve splitting (when zooming in) and merging
 * (when zooming out) effects:
 * - splitting large clusters into smaller ones when zooming in.
 * - merging small clusters into bigger ones when zooming out.
 *
 * NOTES: the position to animate to/from for each cluster is heuristically
 * calculated by finding the first overlapping cluster. This means that:
 * - when zooming in:
 *    if a cluster on a higher zoom level is made from multiple clusters on
 *    a lower zoom level the split will only animate the new cluster from
 *    one of them.
 * - when zooming out:
 *    if a cluster on a higher zoom level is split into multiple parts to join
 *    multiple clusters at a lower zoom level, the merge will only animate
 *    the old cluster into one of them.
 * Because of these limitations, the actual cluster sizes may not add up, for
 * example people may see 3 clusters of size 3, 4, 5 joining to make up a cluster
 * of only 8 for non-hierachical clusters. And vice versa, a cluster of 8 may
 * split into 3 clusters of size 3, 4, 5. For hierarchical clusters, the numbers
 * should add up however.
 *
 * Defaults to YES.
 */
@property(nonatomic) BOOL animatesClusters;

/**
 * Determines the minimum number of cluster items inside a cluster.
 * Clusters smaller than this threshold will be expanded.
 *
 * Defaults to 4.
 */
@property(nonatomic) NSUInteger minimumClusterSize;

/**
 * Sets the maximium zoom level of the map on which the clustering
 * should be applied. At zooms above this level, clusters will be expanded.
 * This is to prevent cases where items are so close to each other than they
 * are always grouped.
 *
 * Defaults to 20.
 */
@property(nonatomic) NSUInteger maximumClusterZoom;

/**
 * Sets the animation duration for marker splitting/merging effects.
 * Measured in seconds.
 *
 * Defaults to 0.5.
 */
@property(nonatomic) double animationDuration;

/**
 * Allows setting a zIndex value for the clusters.  This becomes useful
 * when using multiple cluster data sets on the map and require a predictable
 * way of displaying multiple sets with a predictable layering order.
 *
 * If no specific zIndex is not specified during the initialization, the
 * default zIndex is '1'.  Larger zIndex values are drawn over lower ones
 * similar to the zIndex value of MFMarkers.
 */
@property(nonatomic) int zIndex;

/** Sets to further customize the renderer. */
@property(nonatomic, nullable, weak) id<MFUClusterRendererDelegate> delegate;

/**
 * Returns currently active markers.
 */
@property(nonatomic, readonly) NSArray<MFMarker *> *markers;

/**
 * If returns NO, cluster items will be expanded and rendered as normal markers.
 * Subclass can override this method to provide custom logic.
 */
- (BOOL)shouldRenderAsCluster:(id<MFUCluster>)cluster atZoom:(float)zoom;

@end

NS_ASSUME_NONNULL_END
