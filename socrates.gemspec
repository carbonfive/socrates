lib = File.expand_path("lib", __dir__)
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

  spec.required_ruby_version = ">= 2.4.0"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "rubocop", "= 0.60.0"
  spec.add_development_dependency "simplecov", "~> 0.16"
  spec.add_development_dependency "timecop", "~> 0.9"

  spec.add_dependency "activesupport", ">= 5.1"
  spec.add_dependency "celluloid-io", ">= 0.17.3"
  spec.add_dependency "hashie", ">= 3.6"
  spec.add_dependency "redis", ">= 4.0.3"
  spec.add_dependency "slack-ruby-client", ">= 0.13.1"
end
