# frozen_string_literal: true

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
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata = {
    "homepage_uri" => "https://github.com/Shopify/toxiproxy",
    "source_code_uri" => "https://github.com/Shopify/toxiproxy-ruby",
    "changelog_uri" => "https://github.com/Shopify/toxiproxy-ruby/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/Shopify/toxiproxy-ruby",
    "allowed_push_host" => "https://rubygems.org",
  }

  spec.files = Dir.glob("{lib,data}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  spec.files += ["LICENSE", "README.md"]

  spec.require_paths = ["lib"]
end
