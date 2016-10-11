#
# Be sure to run `pod lib lint NSURLSession-Mock.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "NSURLSession-Mock"
  s.version          = "1.0.0"
  s.summary          = "Stub responses from NSURLSession"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
			This pod will add methods to NSURLSession to help stubbing server responses, making functional testing simpler
                       DESC

  s.homepage         = "https://github.com/net-a-porter-mobile/NSURLSession-Mock"
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { "Sam Dean" => "sam.dean@net-a-porter.com" }
  s.source           = { :git => "https://github.com/net-a-porter-mobile/NSURLSession-Mock.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.compiler_flags = "-Wall -Werror -Wextra"

  s.source_files = 'Pod/Classes/**/*'

end

