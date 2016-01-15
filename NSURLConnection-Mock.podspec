#
# Be sure to run `pod lib lint NSURLConnection-Mock.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "NSURLConnection-Mock"
  s.version          = "0.1.0"
  s.summary          = "Stub responses from NSURLConnection"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
			This pod will add methods to NSURLConnection to help stubbing server responses, making functional testing simpler
                       DESC

  s.homepage         = "https://github.com/net-a-porter-mobile/NSURLConnection-Mock"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { "Sam Dean" => "sam.dean@net-a-porter.com" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/NSURLConnection-Mock.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.compiler_flags = "-Wall -Werror -Wextra"

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'NSURLConnection-Mock' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
