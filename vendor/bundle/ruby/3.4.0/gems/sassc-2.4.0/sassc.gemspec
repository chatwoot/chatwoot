# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sassc/version"

Gem::Specification.new do |spec|

  spec.name          = "sassc"
  spec.version       = SassC::VERSION
  spec.authors       = ["Ryan Boland"]
  spec.email         = ["ryan@tanookilabs.com"]
  spec.summary       = "Use libsass with Ruby!"
  spec.description   = "Use libsass with Ruby!"
  spec.homepage      = "https://github.com/sass/sassc-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.required_ruby_version = ">= 2.0.0"

  spec.require_paths = ["lib"]

  spec.platform      = Gem::Platform::RUBY
  spec.extensions    = ["ext/extconf.rb"]

  spec.add_development_dependency "minitest", "~> 5.5.1"
  spec.add_development_dependency "minitest-around"
  spec.add_development_dependency "test_construct"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rake-compiler"
  spec.add_development_dependency "rake-compiler-dock"

  spec.add_dependency "ffi", "~> 1.9"

  gem_dir = File.expand_path(File.dirname(__FILE__)) + "/"

  libsass_dir = File.join(gem_dir, 'ext', 'libsass')
  if !File.directory?(libsass_dir) ||
      # '.', '..', and possibly '.git' from a failed checkout:
      Dir.entries(libsass_dir).size <= 3
    Dir.chdir(__dir__) { system('git submodule update --init') } or
        fail 'Could not fetch libsass'
  end

  # Write a VERSION file for non-binary gems (for `SassC::Native.version`).
  if File.exist?(File.join(libsass_dir, '.git'))
    libsass_version = Dir.chdir(libsass_dir) do
      %x[git describe --abbrev=4 --dirty --always --tags].chomp
    end
    File.write(File.join(libsass_dir, 'VERSION'), libsass_version)
  end

  Dir.chdir(libsass_dir) do
    submodule_relative_path = File.join('ext', 'libsass')
    skip_re = %r{(^("?test|docs|script)/)|\.md$|\.yml$}
    only_re = %r{\.[ch](pp)?$}
    `git ls-files`.split($\).each do |filename|
      next if filename =~ skip_re || filename !~ only_re
      spec.files << File.join(submodule_relative_path, filename)
    end
    spec.files << File.join(submodule_relative_path, 'VERSION')
  end

end
