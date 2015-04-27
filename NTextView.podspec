#
# Be sure to run `pod lib lint NTextView.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "NTextView"
  s.version          = "0.1.0"
  s.summary          = "Custom text view"
  s.description      = <<-DESC
                       Custom text view with placeholder.
                       DESC
  s.homepage         = "https://github.com/naithar/NTextView"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Naithar" => "devias.naith@gmail.com" }
  s.source           = { :git => "https://github.com/naithar/NTextView.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/naithar'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'NTextView' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Classes/**/*.h'
end
