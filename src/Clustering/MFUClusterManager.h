#import <Foundation/Foundation.h>

#import <Map4dMap/Map4dMap.h>

#import "MFUClusterAlgorithm.h"
#import "MFUClusterItem.h"
#import "MFUClusterRenderer.h"

NS_ASSUME_NONNULL_BEGIN

@class MFUClusterManager;

/**
 * Delegate for events on the MFUClusterManager.
 */
@protocol MFUClusterManagerDelegate <NSObject>

@optional

/**
 * Called when the user taps on a cluster marker.
 * @return YES if this delegate handled the tap event,
 * and NO to pass this tap event to other handlers.
 */
- (BOOL)clusterManager:(MFUClusterManager *)clusterManager didTapCluster:(id<MFUCluster>)cluster;

/**
 * Called when the user taps on a cluster item marker.
 * @return YES if this delegate handled the tap event,
 * and NO to pass this tap event to other handlers.
 */
- (BOOL)clusterManager:(MFUClusterManager *)clusterManager
     didTapClusterItem:(id<MFUClusterItem>)clusterItem;

@end

/**
 * This class groups many items on a map based on zoom level.
 * Cluster items should be added to the map via this class.
 */
@interface MFUClusterManager : NSObject <MFMapViewDelegate>

/**
 * The default initializer is not available. Use initWithMap:algorithm:renderer instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Returns a new instance of the MFUClusterManager class defined by it's |algorithm| and |renderer|.
 */
- (instancetype)initWithMap:(MFMapView *)mapView
                  algorithm:(id<MFUClusterAlgorithm>)algorithm
                   renderer:(id<MFUClusterRenderer>)renderer NS_DESIGNATED_INITIALIZER;

/**
 * Returns the clustering algorithm.
 */
@property(nonatomic, readonly) id<MFUClusterAlgorithm> algorithm;

/**
 * MFUClusterManager |delegate|.
 * To set it use the setDelegate:mapDelegate: method.
 */
@property(nonatomic, readonly, weak, nullable) id<MFUClusterManagerDelegate> delegate;

/**
 * The MFMapViewDelegate delegate that map events are being forwarded to.
 * To set it use the setDelegate:mapDelegate: method.
 */
@property(nonatomic, readonly, weak, nullable) id<MFMapViewDelegate> mapDelegate;

/**
 * Sets a |mapDelegate| to listen to forwarded map events.
 */
- (void)setMapDelegate:(id<MFMapViewDelegate> _Nullable)mapDelegate;

/**
 * Sets MFUClusterManagerDelegate |delegate| and optionally
 * provides a |mapDelegate| to listen to forwarded map events.
 *
 * NOTES: This method changes the |delegate| property of the
 * managed |mapView| to this object, intercepting events that
 * the MFUClusterManager wants to action or rebroadcast
 * to the MFUClusterManagerDelegate. Any remaining events are
 * then forwarded to the new |mapDelegate| provided here.
 *
 * EXAMPLE: [clusterManager setDelegate:self mapDelegate:_map.delegate];
 * In this example self will receive type-safe MFUClusterManagerDelegate
 * events and other map events will be forwarded to the current map delegate.
 */
- (void)setDelegate:(id<MFUClusterManagerDelegate> _Nullable)delegate
        mapDelegate:(id<MFMapViewDelegate> _Nullable)mapDelegate;

/**
 * Adds a cluster item to the collection.
 */
- (void)addItem:(id<MFUClusterItem>)item;

/**
 * Adds multiple cluster items to the collection.
 */
- (void)addItems:(NSArray<id<MFUClusterItem>> *)items;

/**
 * Removes a cluster item from the collection.
 */
- (void)removeItem:(id<MFUClusterItem>)item;

/**
 * Removes all items from the collection.
 */
- (void)clearItems;

/**
 * Called to arrange items into groups.
 * - This method will be automatically invoked when the map's zoom level changes.
 * - Manually invoke this method when new items have been added to rearrange items.
 */
- (void)cluster;

@end

NS_ASSUME_NONNULL_END
