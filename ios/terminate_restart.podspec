#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint terminate_restart.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'terminate_restart'
  s.version          = '1.1.0'
  s.summary          = 'A Flutter plugin to terminate and restart the app'
  s.description      = <<-DESC
A Flutter plugin that helps you to terminate and restart your app on both iOS and Android platforms.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'terminate_restart/Sources/terminate_restart/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
