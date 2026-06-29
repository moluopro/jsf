# Copyright (C) 2025 moluopro. All rights reserved.
# Github: https://github.com/moluopro

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint jsf.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  quickjs_version = File.read(File.join(__dir__, '../src/quickjs/VERSION')).strip

  s.name             = 'jsf'
  s.version          = '1.0.0'
  s.summary          = 'A high performance JavaScript engine.'
  s.description      = <<-DESC
A high performance JavaScript engine, available out of the box in Flutter.
                       DESC
  s.homepage         = 'https://github.com/moluopro/jsf'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'moluopro' => 'moluopro@gmail.com' }

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'GCC_PREPROCESSOR_DEFINITIONS' => "_GNU_SOURCE=1 CONFIG_VERSION=\\\"#{quickjs_version}\\\"",
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/../src $(PODS_TARGET_SRCROOT)/../src/quickjs',
    'OTHER_CFLAGS' => '-fwrapv -Wno-shorten-64-to-32 -Wno-conditional-uninitialized -Wno-comma'
  }

  s.source           = { :path => '.' }
  s.source_files = [
    'Classes/jsf.c',
    'Classes/quickjs/cutils.c',
    'Classes/quickjs/dtoa.c',
    'Classes/quickjs/libregexp.c',
    'Classes/quickjs/libunicode.c',
    'Classes/quickjs/quickjs.c'
  ]

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'jsf_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.swift_version = '5.0'
end
