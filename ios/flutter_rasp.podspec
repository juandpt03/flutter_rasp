Pod::Spec.new do |s|
  s.name             = 'flutter_rasp'
  s.version          = '6.1.3'
  s.summary          = 'RASP (Runtime Application Self-Protection) plugin for Flutter.'
  s.description      = <<-DESC
A comprehensive RASP plugin for Flutter that detects root, jailbreak, emulators, debuggers, hooks, repackaging, untrusted installs, VPN, developer mode, device passcode, secure hardware, obfuscation, time spoofing, location spoofing, multi-instance, and screen capture threats.
                       DESC
  s.homepage         = 'https://github.com/juandpt03/flutter_rasp'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'juandpt03' => 'juandpt03@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_rasp/Sources/flutter_rasp/**/*.swift'
  s.vendored_frameworks = 'flutter_rasp/FlutterRaspCore.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
  s.resource_bundles = {'flutter_rasp_privacy' => ['flutter_rasp/Sources/flutter_rasp/PrivacyInfo.xcprivacy']}
end
