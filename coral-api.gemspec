# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "coral-api/version"

Gem::Specification.new do |spec|
  spec.name          = "coral-api"
  spec.version       = Coral::VERSION
  spec.authors       = ["neil.huang"]
  spec.email         = ["catfishuang@hotmail.com"]

  spec.summary       = "an automation test framework"
  spec.description   = "for api and app automation test"
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://mygemserver.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir["project/lib/*/*"]+Dir["project/sample/*"]+Dir["project/*"]+Dir["exe/*"]+Dir["project/config/*"]+Dir["project/jar/*"]+Dir["project/lib/*"]+Dir["project/bin/*/*"]+Dir["project/bin/*"]+Dir["lib/*/*"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
