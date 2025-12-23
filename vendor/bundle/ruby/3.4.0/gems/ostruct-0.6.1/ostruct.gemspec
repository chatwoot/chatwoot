# frozen_string_literal: true

name = File.basename(__FILE__, ".gemspec")
version = ["lib", Array.new(name.count("-")+1, ".").join("/")].find do |dir|
  break File.foreach(File.join(__dir__, dir, "#{name.tr('-', '/')}.rb")) do |line|
    /^\s*VERSION\s*=\s*"(.*)"/ =~ line and break $1
  end rescue nil
end

Gem::Specification.new do |spec|
  spec.name          = name
  spec.version       = version
  spec.authors       = ["Marc-Andre Lafortune"]
  spec.email         = ["ruby-core@marc-andre.ca"]

  spec.summary       = %q{Class to build custom data structures, similar to a Hash.}
  spec.description   = %q{Class to build custom data structures, similar to a Hash.}
  spec.homepage      = "https://github.com/ruby/ostruct"
  spec.licenses      = ["Ruby", "BSD-2-Clause"]
  spec.required_ruby_version = ">= 2.5.0"

  spec.files         = [".gitignore", "Gemfile", "COPYING", "BSDL", "README.md", "Rakefile", "bin/console", "bin/setup", "lib/ostruct.rb", "ostruct.gemspec"]
  spec.require_paths = ["lib"]
end
