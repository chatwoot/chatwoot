# frozen_string_literal: true

name = File.basename(__FILE__, ".gemspec")
version = ["lib", Array.new(name.count("-"), "..").join("/")].find do |dir|
  break File.foreach(File.join(__dir__, dir, "#{name.tr('-', '/')}.rb")) do |line|
    /^\s*VERSION\s*=\s*"(.*)"/ =~ line and break $1
  end rescue nil
end

Gem::Specification.new do |spec|
  spec.name          = name
  spec.version       = version
  spec.authors       = ["Yukihiro Matsumoto"]
  spec.email         = ["matz@ruby-lang.org"]

  spec.summary       = %q{Simple Mail Transfer Protocol client library for Ruby.}
  spec.description   = %q{Simple Mail Transfer Protocol client library for Ruby.}
  spec.homepage      = "https://github.com/ruby/net-smtp"
  spec.licenses      = ["Ruby", "BSD-2-Clause"]
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files         = %w[
    LICENSE.txt
    lib/net/smtp.rb
    net-smtp.gemspec
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "net-protocol"
end
