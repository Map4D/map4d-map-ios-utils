#ifndef MFGeometryUtils_h
#define MFGeometryUtils_h

#import <CoreLocation/CoreLocation.h>

typedef struct MFMapPoint {
  double x;
  double y;
} MFMapPoint;

/** Projects |coordinate| to the map. |coordinate| must be valid. */
FOUNDATION_EXPORT
MFMapPoint MFProject(CLLocationCoordinate2D coordinate);

/** Unprojects |point| from the map. point.x must be in [-1, 1]. */
FOUNDATION_EXPORT
CLLocationCoordinate2D MFUnproject(MFMapPoint point);

#endif /* MFGeometryUtils_h */
