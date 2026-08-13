Pod::Spec.new do |s|
  s.name = 'BitmovinGoogleDAIPlayer'
  s.version = '0.2.1'
  s.summary = 'Google DAI integration for the Bitmovin Player iOS SDK'
  s.description = 'Enables Google Dynamic Ad Insertion with the Bitmovin Player iOS SDK.'
  s.homepage = 'https://github.com/bitmovin/bitmovin-player-ios-integrations-google-dai'
  s.license = { type: 'MIT', file: 'LICENSE.md' }
  s.author = { 'Bitmovin' => 'player-sdks@bitmovin.com' }
  s.source = {
    git: 'https://github.com/bitmovin/bitmovin-player-ios-integrations-google-dai.git',
    tag: s.version.to_s
  }

  s.ios.deployment_target = '15.0'
  s.tvos.deployment_target = '15.0'
  s.swift_version = '5.10'
  s.static_framework = true

  s.source_files = 'BitmovinGoogleDAIPlayer/Sources/BitmovinGoogleDAIPlayer/**/*.swift'

  s.dependency 'BitmovinPlayer', '~> 3.119'
  s.ios.dependency 'GoogleAds-IMA-iOS-SDK', '>= 3.26.1'
  s.tvos.dependency 'GoogleAds-IMA-tvOS-SDK', '>= 4.15.1'
end
