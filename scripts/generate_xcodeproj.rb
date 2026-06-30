#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'

PROJECT_PATH = 'FormulaPad.xcodeproj'
APP_NAME = 'FormulaPad'
APP_TARGET = 'FormulaPad'
TEST_TARGET = 'FormulaPadTests'

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes['LastUpgradeCheck'] = '2620'
project.root_object.attributes['TargetAttributes'] ||= {}

app_target = project.new_target(:application, APP_TARGET, :ios, '17.0')
project.root_object.attributes['TargetAttributes'][app_target.uuid] = {
  'CreatedOnToolsVersion' => '26.2'
}

app_group = project.main_group.new_group(APP_NAME)

def add_source_files(group, target, directory)
  Dir.glob("#{directory}/**/*.swift").sort.each do |path|
    file_ref = group.new_file(path)
    target.add_file_references([file_ref])
  end
end

def add_resource(group, target, path)
  file_ref = group.new_file(path)
  target.add_resources([file_ref])
end

add_source_files(app_group, app_target, APP_NAME)
add_resource(app_group, app_target, "#{APP_NAME}/Resources/Assets.xcassets")
Dir.glob("#{APP_NAME}/Resources/*.plist").sort.each do |path|
  next if File.basename(path) == 'Info.plist'

  add_resource(app_group, app_target, path)
end
Dir.glob("#{APP_NAME}/Resources/*.lproj/*.strings").sort.each do |path|
  add_resource(app_group, app_target, path)
end
add_resource(app_group, app_target, "#{APP_NAME}/Resources/StoreKit/FormulaPad.storekit")

app_target.build_configurations.each do |config|
  settings = config.build_settings
  settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['CURRENT_PROJECT_VERSION'] = '1'
  settings['DEVELOPMENT_TEAM'] = ''
  settings['ENABLE_PREVIEWS'] = 'YES'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['INFOPLIST_FILE'] = "#{APP_NAME}/Resources/Info.plist"
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  settings['MARKETING_VERSION'] = '1.0.0'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.zhouyajie.formulapad'
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator'
  settings['SUPPORTS_MACCATALYST'] = 'NO'
  settings['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1'
end

tests_dir = 'FormulaPadTests'
test_target = nil
if Dir.exist?(tests_dir)
  test_group = project.main_group.new_group(TEST_TARGET)
  test_target = project.new_target(:unit_test_bundle, TEST_TARGET, :ios, '17.0')
  test_target.add_dependency(app_target)
  project.root_object.attributes['TargetAttributes'][test_target.uuid] = {
    'CreatedOnToolsVersion' => '26.2',
    'TestTargetID' => app_target.uuid
  }
  add_source_files(test_group, test_target, tests_dir)
  test_target.build_configurations.each do |config|
    settings = config.build_settings
    settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
    settings['CODE_SIGN_STYLE'] = 'Automatic'
    settings['DEVELOPMENT_TEAM'] = ''
    settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.zhouyajie.formulapad.tests'
    settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    settings['SWIFT_VERSION'] = '5.0'
    settings['TARGETED_DEVICE_FAMILY'] = '1'
    settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/FormulaPad.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/FormulaPad'
  end
end

project.save
scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app_target, test_target, launch_target: app_target)
scheme.save_as(project.path, APP_TARGET, true)

scheme_path = File.join(PROJECT_PATH, 'xcshareddata', 'xcschemes', "#{APP_TARGET}.xcscheme")
scheme_xml = File.read(scheme_path)
unless scheme_xml.include?('StoreKitConfigurationFileReference')
  scheme_xml = scheme_xml.sub(
    "      allowLocationSimulation = \"YES\">\n",
    "      allowLocationSimulation = \"YES\">\n" \
    "      <StoreKitConfigurationFileReference\n" \
    "         identifier = \"../../../FormulaPad/Resources/StoreKit/FormulaPad.storekit\">\n" \
    "      </StoreKitConfigurationFileReference>\n"
  )
  File.write(scheme_path, scheme_xml)
end
