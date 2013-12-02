Pod::Spec.new do |s|
  s.name         = "GBRetractableTabBar"
  s.version      = "1.0.3"
  s.summary      = "iOS Control for a retractable tab bar that supports full customisation in terms of sizing, behaviour, and custom views."
  s.homepage     = "https://github.com/lmirosevic/GBRetractableTabBar"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Luka Mirosevic" => "luka@goonbee.com" }
  s.platform     = :ios, '5.0'
  s.source       = { :git => "https://github.com/lmirosevic/GBRetractableTabBar.git", :tag => "1.0.3" }
  s.source_files  = 'GBRetractableTabBar'
  s.public_header_files = 'GBRetractableTabBar/GBRetractableTabBar.h', 'GBRetractableTabBar/GBRetractableTabBarControlViewProtocol.h', 'GBRetractableTabBar/GBRetractableTabBar+UINavigationController.h'
  s.requires_arc = true

  s.dependency 'GBToolbox'
end
