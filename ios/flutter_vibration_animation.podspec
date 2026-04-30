Pod::Spec.new do |s|
  s.name             = 'flutter_vibration_animation'
  s.version          = '0.1.0'
  s.summary          = 'Comprehensive vibration and haptic feedback for Flutter — Android & iOS.'
  s.description      = <<-DESC
Vibration and haptic feedback for Flutter with full Android and iOS implementations.
Supports impact / notification / selection feedback, predefined OS effects,
custom waveforms, Core Haptics intensity-and-sharpness patterns, and capability detection.
                       DESC
  s.homepage         = 'https://github.com/erykkruk/flutter_vibration_animation'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Eryk Kruk' => 'eryk.kruk@codigee.com' }
  s.source           = { :http => 'https://github.com/erykkruk/flutter_vibration_animation' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'

  s.frameworks = 'UIKit', 'CoreHaptics', 'AudioToolbox'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
end
