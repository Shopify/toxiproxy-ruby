require_relative "lib/toxiproxy/version"

Gem::Specification.new do |spec|
  spec.name        = "toxiproxy"
  spec.version     = Toxiproxy::VERSION
  spec.authors     = ["Simon Eskildsen", "Jacob Wirth"]
  spec.email       = "opensource@shopify.com"
  spec.summary     = "Ruby library for Toxiproxy"
  spec.description = "A Ruby library for controlling Toxiproxy. Can be used in resiliency testing."
  spec.homepage    = "https://github.com/Shopify/toxiproxy"
  spec.license     = "MIT"

  spec.metadata = {
    "homepage_uri" => "https://github.com/Shopify/toxiproxy",
    "documentation_uri" => "https://github.com/Shopify/toxiproxy-ruby",
    "allowed_push_host" => "https://rubygems.org"
  }

  spec.files = Dir.glob("{lib,data}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  spec.files += ["LICENSE", "README.md"]
  spec.test_files = Dir.glob("{test}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  spec.require_paths = ["lib"]
end
