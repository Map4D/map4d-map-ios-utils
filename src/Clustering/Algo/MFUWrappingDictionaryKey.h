#import <Foundation/Foundation.h>

/**
 * Wraps an object which does not implement NSCopying to be used as NSDictionary keys.
 * This class will forward -hash and -isEqual methods to the underlying object.
 */
@interface MFUWrappingDictionaryKey : NSObject<NSCopying>

- (instancetype)initWithObject:(id)object;

@end
