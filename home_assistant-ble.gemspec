# coding: utf-8

lib = File.expand_path('../lib', __FILE__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'home_assistant/ble/version'

Gem::Specification.new do |spec|
  spec.name          = 'home_assistant-ble'
  spec.version       = HomeAssistant::Ble::VERSION
  spec.version       = "#{spec.version}-alpha-#{ENV['TRAVIS_BUILD_NUMBER']}" if ENV['TRAVIS']
  spec.version       = ENV['TRAVIS_TAG'] if ENV['TRAVIS_TAG'] && !ENV['TRAVIS_TAG'].empty?
  spec.authors       = ['Grégoire Seux']
  spec.email         = ['grego_homeassistant@familleseux.net']

  spec.summary       = 'Companion app for home-assistant sending event about BLE devices'
  spec.description   = 'home-assistant does not cope well with bluetooth on raspberry pi. This gem sends event to HA.'
  spec.homepage      = 'https://github.com/kamaradclimber/home_assistant-ble'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop', '~> 0.49.0'

  spec.add_runtime_dependency 'ble'
  spec.add_runtime_dependency 'mash'
  spec.add_runtime_dependency 'cap2'
end
