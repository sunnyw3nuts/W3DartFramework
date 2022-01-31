
Pod::Spec.new do |spec|

  spec.name         = "W3DartFramework"
  spec.version      = "1.0.0"
  spec.summary      = "This is a best framework for bug submitted."
  spec.description  = "I have no idea what to write as a description"

  spec.homepage     = "https://github.com/samirkaila/W3Dart-SDK-iOS"
  spec.license      = "MIT"
  spec.author             = { "w3nuts" => "" }
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "git@github.com:samirkaila/W3Dart-SDK-iOS.git", :tag => spec.version.to_s }
  spec.source_files  = "W3DartFramework/**/*.{swift}"
  spec.swift_version = "5.0"
end
