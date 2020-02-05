Pod::Spec.new do |s|
s.name         = "DHNetwork"
s.version      = "1.0.0"
s.summary      = "网络工具"
s.swift_versions = "4.0"
s.description  = <<-DESC
智控车云网络工具
DESC
s.homepage     = "https://github.com/DajuanM/DHNetwork"
s.license      = "MIT"
s.author       = { "Aiden" => "252289287@qq.com" }
s.source       = { :git => "https://github.com/DajuanM/DHNetwork.git", :tag => "#{s.version}" }
s.source_files  = "DHNetwork","DHNetwork/*.swift"
s.requires_arc = true
s.ios.deployment_target = '10.0'
s.dependency "Moya/RxSwift"
end