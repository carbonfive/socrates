# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "socrates/version"

Gem::Specification.new do |spec|
  spec.name     = "socrates"
  spec.version  = Socrates::VERSION
  spec.license  = "MIT"
  spec.authors  = ["Christian Nelson"]
  spec.email    = ["christian@carbonfive.com"]

  spec.summary  = "A micro-framework for building stateful conversational bots."
  spec.homepage = "https://github.com/carbonfive/socrates"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.5"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "rubocop", "~> 0.48.1"
  spec.add_development_dependency "timecop", "~> 0.8.1"

  spec.add_dependency "activesupport", ">= 5.0.2"
  spec.add_dependency "celluloid-io", ">= 0.17.3"
  spec.add_dependency "hashie", ">= 3.5.5"
  spec.add_dependency "redis", ">= 3.3.3"
  spec.add_dependency "slack-ruby-client", ">= 0.8.1"
end
