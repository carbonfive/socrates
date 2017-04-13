# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'socrates/version'

Gem::Specification.new do |spec|
  spec.name          = "socrates"
  spec.version       = Socrates::VERSION
  spec.authors       = ["Christian Nelson"]
  spec.email         = ["christian@carbonfive.com"]

  spec.summary       = %q{A micro framework for building conversational bots.}
  spec.homepage      = "https://github.com/carbonfive/socrates"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5"

  spec.add_dependency 'activesupport', '>= 5.0.02'
  spec.add_dependency 'celluloid-io', '>= 0.17.3'
  spec.add_dependency 'hashie', '>= 3.5.5'
  spec.add_dependency 'redis', '>= 3.3.3'
  spec.add_dependency 'slack-ruby-client', '>= 0.8.0'
end
