#import "MFGeometryUtils.h"

static const double kMFMaxLatitude = 85.051128779806589;//85.051128779806604;
static const double kMFMaxLongitude = 180.0;

MFMapPoint MFProject(CLLocationCoordinate2D coordinate) {
  MFMapPoint point;
  point.x = coordinate.longitude / kMFMaxLongitude;
  point.y = coordinate.latitude / kMFMaxLatitude;
  return point;
}

CLLocationCoordinate2D MFUnproject(MFMapPoint point) {
  CLLocationDegrees latitude = point.y * kMFMaxLatitude;
  CLLocationDegrees longitude = point.x * kMFMaxLongitude;
  return CLLocationCoordinate2DMake(latitude, longitude);
}
