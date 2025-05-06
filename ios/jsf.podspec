# Copyright (C) 2025 moluopro. All rights reserved.
# Github: https://github.com/moluopro

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint jsf.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'jsf'
  s.version          = '0.6.1'
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
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
