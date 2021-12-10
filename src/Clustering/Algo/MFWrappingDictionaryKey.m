#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MFWrappingDictionaryKey.h"

@implementation MFWrappingDictionaryKey {
  id _object;
}

- (instancetype)initWithObject:(id)object {
  if ((self = [super init])) {
    _object = object;
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  MFWrappingDictionaryKey *newKey = [[self class] allocWithZone:zone];
  if (newKey) {
    newKey->_object = _object;
  }
  return newKey;
}

// Forwards hash to _object.
- (NSUInteger)hash {
  return [_object hash];
}

// Forwards isEqual to _object.
- (BOOL)isEqual:(id)object {
  if (self == object) return YES;

  if ([object class] != [self class]) return NO;

  MFWrappingDictionaryKey *other = (MFWrappingDictionaryKey *)object;
  return [_object isEqual:other->_object];
}

@end

