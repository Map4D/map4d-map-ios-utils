Pod::Spec.new do |s|
  s.name             = 'Map4dMapUtils'
  s.version          = '0.1.0'
  s.summary          = 'A utilities library for use with Map4dMap SDK for iOS.'
  s.description      = <<-DESC
                        A utilities library for use with Map4dMap SDK for iOS.
                       DESC

  s.author           = 'IOTLink'
  s.homepage         = 'https://map4d.vn'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.source           = { :git => 'https://github.com/map4d/map4d-map-ios-utils.git',
                         :tag => s.version.to_s }

  s.platform         = :ios, '9.3'
  s.requires_arc     = true
  s.static_framework = true

  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.pod_target_xcconfig  = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  
  s.private_header_files = "src/*/Private/*.h"
  s.public_header_files  = "src/**/*.h"
  s.source_files         = "src/**/*.{h,m,swift}"
  
  # Dependencies
  s.dependency 'Map4dMap', '~> 2.0.5'
  
end
