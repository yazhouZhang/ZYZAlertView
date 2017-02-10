

Pod::Spec.new do |s|

  s.name         = "ZYZAlertView"
  s.version      = "0.0.1"
  s.summary      = "A short description of ZYZAlertView."
  s.description  = <<-DESC
                    design by my self
                   DESC

  s.homepage     = "https://github.com/yazhouZhang/ZYZAlertView"

  s.license      = "MIT"

  s.author             = { "yazhouZhang" => "1532226710@qq.com" }

  s.ios.deployment_target = "6.0"

  s.source       = { :git => "https://github.com/yazhouZhang/ZYZAlertView.git", :tag => "0.0.1" }

  s.source_files  = "ZYZAlertView/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"

  s.resource  = "close.png"

  s.requires_arc = true

end
