Pod::Spec.new do |s|
  s.name             = "SPXCoreData"
  s.version          = "1.0.0"
  s.summary          = "My personal approach to the CoreData stack."
  s.homepage         = "https://github.com/shaps80/SPXCoreData"
  s.license          = 'MIT'
  s.author           = { "Shaps Mohsenin" => "shapsuk@me.com" }
  s.source           = { :git => "https://github.com/shaps80/SPXCoreData.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/shaps'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
  s.dependency 'SPXDefines'
end
