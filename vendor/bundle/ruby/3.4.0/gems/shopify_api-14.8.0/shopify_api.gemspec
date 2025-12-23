# frozen_string_literal: true

$LOAD_PATH.push(File.expand_path("../lib", __FILE__))
require "shopify_api/version"

Gem::Specification.new do |s|
  s.name = "shopify_api"
  s.version = ShopifyAPI::VERSION
  s.author = "Shopify"

  s.summary = "The gem for accessing the Shopify API"
  s.description = <<~HERE
    This gem allows Ruby developers to programmatically access the admin
    section of Shopify stores.
  HERE
  s.email = "developers@shopify.com"
  s.homepage = "https://shopify.dev/docs/apps"

  s.metadata["allowed_push_host"] = "https://rubygems.org"

  s.extra_rdoc_files = [
    "LICENSE",
    "README.md",
  ]
  s.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test)/}) }
  end

  s.rdoc_options = ["--charset=UTF-8"]

  s.license = "MIT"

  s.required_ruby_version = ">= 3.0"

  s.add_runtime_dependency("activesupport")
  s.add_runtime_dependency("concurrent-ruby")
  s.add_runtime_dependency("hash_diff")
  s.add_runtime_dependency("httparty")
  s.add_runtime_dependency("jwt")
  s.add_runtime_dependency("oj")
  s.add_runtime_dependency("openssl")
  s.add_runtime_dependency("securerandom")
  s.add_runtime_dependency("sorbet-runtime")
  s.add_runtime_dependency("zeitwerk", "~> 2.5")
end
