#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Defines a contract for cluster icon generation.
 */
@protocol MFClusterIconGenerator<NSObject>

/**
 * Generates an icon with the given size.
 */
- (UIImage *)iconForSize:(NSUInteger)size;

@end
