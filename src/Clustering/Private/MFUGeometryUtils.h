#ifndef MFUGeometryUtils_h
#define MFUGeometryUtils_h

#import <CoreLocation/CoreLocation.h>

typedef struct MFUMapPoint {
  double x;
  double y;
} MFUMapPoint;

/** Projects |coordinate| to the map. |coordinate| must be valid. */
FOUNDATION_EXPORT
MFUMapPoint MFUProject(CLLocationCoordinate2D coordinate);

/** Unprojects |point| from the map. point.x must be in [-1, 1]. */
FOUNDATION_EXPORT
CLLocationCoordinate2D MFUUnproject(MFUMapPoint point);

#endif /* MFUGeometryUtils_h */
