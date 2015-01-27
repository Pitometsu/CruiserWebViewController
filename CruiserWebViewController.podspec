
@version = "5.0"

Pod::Spec.new do |s|
  s.name           = "CruiserWebViewController"
  s.version        = @version
  s.summary        = "Yet another one WebKit browser controller with enhanced navigation and additional controls."
  s.homepage       = "https://github.com/pitometsu/CruiserWebViewController"
  s.license        = { :type => 'MIT', :file => 'LICENSE' }
  s.author         = { "Ignacio Romero Z." => "iromero@dzen.cl",
                       "Yuriy Pitomets V." => "pitometsu@gmail.com"}
  s.source         = { :git => "https://github.com/pitometsu/CruiserWebViewController.git",
                       :tag => "v#{s.version}" }

  s.platform       = :ios, '8.0'
  s.requires_arc   = true

  s.source_files   = 'Source/Classes/*.{h,m}'
  s.resources      = 'Source/Resources/*.*'
  s.framework      = 'UIKit', 'WebKit'
end
