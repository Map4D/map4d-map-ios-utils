#import <Foundation/Foundation.h>

#import "MFCluster.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Defines a cluster where its position is fixed upon construction.
 */
@interface MFStaticCluster : NSObject <MFCluster>

/**
 * The default initializer is not available. Use initWithPosition: instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Returns a new instance of the MFStaticCluster class defined by it's position.
 */
- (instancetype)initWithPosition:(CLLocationCoordinate2D)position NS_DESIGNATED_INITIALIZER;

/**
 * Returns the position of the cluster.
 */
@property(nonatomic, readonly) CLLocationCoordinate2D position;

/**
 * Returns the number of items in the cluster.
 */
@property(nonatomic, readonly) NSUInteger count;

/**
 * Returns a copy of the list of items in the cluster.
 */
@property(nonatomic, readonly) NSArray<id<MFClusterItem>> *items;

/**
 * Adds an item to the cluster.
 */
- (void)addItem:(id<MFClusterItem>)item;

/**
 * Removes an item to the cluster.
 */
- (void)removeItem:(id<MFClusterItem>)item;

@end

NS_ASSUME_NONNULL_END
