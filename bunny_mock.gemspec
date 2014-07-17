# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bunny_mock/version'

Gem::Specification.new do |spec|
  spec.name          = "bunny_mock"
  spec.version       = BunnyMock::VERSION
  spec.authors       = ["svs"]
  spec.email         = ["svs@svs.io"]
  spec.description   = %q{Mocking library for Bunny}
  spec.summary       = %q{Easily mock the bunny gem and pretend you have RabbitMQ running. }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-given"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "bunny"
end
