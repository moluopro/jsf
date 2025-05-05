# Copyright (C) 2025 moluopro. All rights reserved.
# Github: https://github.com/moluopro

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint jsf.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'jsf'
  s.version          = '0.5.4'
  s.summary          = 'A high performance JavaScript engine.'
  s.description      = <<-DESC
A high performance JavaScript engine, available out of the box in Flutter.
                       DESC
  s.homepage         = 'https://github.com/moluopro/jsf'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'moluopro' => 'moluopro@gmail.com' }

  system("rm -rf Classes/*")
  system("cp -r ../src/*.c Classes/")
  system("cp -r ../src/*.h Classes/")

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'GCC_OPTIMIZATION_LEVEL' => '3',
    'OTHER_CFLAGS' => '-O3 -march=native -flto -fno-plt -DCONFIG_BIGNUM'
  }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'jsf_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
