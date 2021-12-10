#import <CoreLocation/CoreLocation.h>

/**
 * This protocol defines the contract for a cluster item.
 */
@protocol MFClusterItem <NSObject>

/**
 * Returns the position of the item.
 */
@property(nonatomic, readonly) CLLocationCoordinate2D position;

@optional
@property(nonatomic, copy, nullable) NSString* title;

@property(nonatomic, copy, nullable) NSString* snippet;

@end
