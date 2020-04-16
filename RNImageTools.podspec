require "json"
version = JSON.parse(File.read("package.json"))["version"]

Pod::Spec.new do |s|
  s.name         = "RNImageTools"
  s.version      = version
  s.summary      = "RNImageTools"

  s.homepage     = "https://github.com/wowmaking/react-native-image-tools"
  s.license      = "MIT"

  s.author       = { "Dmitry Kazlouski" => "dkazlouski@wowmaking.net" }
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/wowmaking/react-native-image-tools", tag: "v" + s.version.to_s }
  s.source_files = "ios/**/*.{h,m}"

  s.module_name  = 'RNImageTools'

  s.dependency "React"
  s.dependency "React-CoreModules"
  s.frameworks = 'UIKit'
end
