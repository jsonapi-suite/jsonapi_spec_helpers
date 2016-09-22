# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsonapi_spec_helpers/version'

Gem::Specification.new do |spec|
  spec.name          = "jsonapi_spec_helpers"
  spec.version       = JsonapiSpecHelpers::VERSION
  spec.authors       = ["Lee Richmond"]
  spec.email         = ["lrichmond1@bloomberg.net"]

  spec.summary       = %q{Spec helpers for jsonapi}
  spec.description   = %q{Includes factory-style payload assertions}
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "actionpack", "~> 5.0"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
