#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "MFUClusterItem.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Defines a generic cluster object.
 */
@protocol MFUCluster <NSObject>

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
@property(nonatomic, readonly) NSArray<id<MFUClusterItem>> *items;

@end

NS_ASSUME_NONNULL_END
