#import "MFUGeometryUtils.h"

static const double kMFUMaxLatitude = 85.051128779806589;//85.051128779806604;
static const double kMFUMaxLongitude = 180.0;

MFUMapPoint MFUProject(CLLocationCoordinate2D coordinate) {
  MFUMapPoint point;
  point.x = coordinate.longitude / kMFUMaxLongitude;
  point.y = coordinate.latitude / kMFUMaxLatitude;
  return point;
}

CLLocationCoordinate2D MFUUnproject(MFUMapPoint point) {
  CLLocationDegrees latitude = point.y * kMFUMaxLatitude;
  CLLocationDegrees longitude = point.x * kMFUMaxLongitude;
  return CLLocationCoordinate2DMake(latitude, longitude);
}
