Pod::Spec.new do |s|
  s.name             = 'LiveCameraView'
  s.version          = '0.3.3'
  s.summary          = 'UIView with live camera feed. Both front and back camera.'
  s.homepage         = 'https://github.com/mikekavouras/LiveCameraView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mike Kavouras' => 'kavourasm@gmail.com' }
  s.source           = { :git => 'https://github.com/mikekavouras/LiveCameraView.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'LiveCameraView/Classes/**/*'

  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  # s.resource_bundles = {
  #   'LiveCameraView' => ['LiveCameraView/Assets/*.png']
  # }
end
