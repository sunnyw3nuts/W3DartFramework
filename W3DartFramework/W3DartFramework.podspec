
Pod::Spec.new do |spec|

  spec.name         = "W3DartFramework"
  spec.version      = "1.0.0"
  spec.summary      = "This is the best bug submit framework ever."
  spec.description  = "I have no idea what to write as a description"
  spec.homepage     = "https://github.com/sunnyw3nuts/W3DartFramework"
  spec.license      = "MIT"
  spec.author             = { "w3nuts" => "" }
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://github.com/sunnyw3nuts/W3DartFramework.git", :tag => spec.version.to_s }
  spec.source_files  = "W3DartFramework/**/*.{swift}"
  spec.swift_versions = "5.0"
end
