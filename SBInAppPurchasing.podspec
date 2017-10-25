#
# Be sure to run `pod lib lint SBInAppPurchasing.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = 'SBInAppPurchasing'
  s.version          = '1.1.0'
  s.summary          = 'Easy In-App Purchasing'
  s.description      = <<-DESC
Make In-App Purchasing simpler! Purchase and restore IAPs with completion callbacks and notifications
                       DESC

  s.homepage         = 'https://github.com/SteveBarnegren/SBInAppPurchasing'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Steve Barnegren' => 'steve.barnegren@gmail.com' }
  s.source           = { :git => 'https://github.com/SteveBarnegren/SBInAppPurchasing.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/stevebarnegren'

  s.ios.deployment_target = '10.0'

  s.source_files = 'SBInAppPurchasing/SBInAppPurchasing/**/*.swift'
 
 end
