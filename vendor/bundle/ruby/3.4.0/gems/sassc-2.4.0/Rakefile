require 'bundler/gem_tasks'

task default: :test

require 'rake/extensiontask'
gem_spec = Gem::Specification.load("sassc.gemspec")

# HACK: Prevent rake-compiler from overriding required_ruby_version,
# because the shared library here is Ruby-agnostic.
# See https://github.com/rake-compiler/rake-compiler/issues/153
module FixRequiredRubyVersion
  def required_ruby_version=(*); end
end
Gem::Specification.send(:prepend, FixRequiredRubyVersion)

Rake::ExtensionTask.new('libsass', gem_spec) do |ext|
  ext.name = 'libsass'
  ext.ext_dir = 'ext'
  ext.lib_dir = 'lib/sassc'
  ext.cross_compile = true
  ext.cross_platform = %w[x86-mingw32 x64-mingw32]

  # Link C++ stdlib statically when building binary gems.
  ext.cross_config_options << '--enable-static-stdlib'

  ext.cross_config_options << '--disable-march-tune-native'

  ext.cross_compiling do |spec|
    spec.files.reject! { |path| File.fnmatch?('ext/*', path) }
  end
end

desc 'Compile all native gems via rake-compiler-dock (Docker)'
task 'gem:native' do
  require 'rake_compiler_dock'

  # The RUBY_CC_VERSION here doesn't matter for the final package.
  # Only one version should be specified, as the shared library is Ruby-agnostic.
  RakeCompilerDock.sh "gem i rake bundler --no-document && bundle && "\
                      "rake clean && rake cross native gem MAKE='nice make -j`nproc`' "\
                      "RUBY_CC_VERSION=2.6.0 CLEAN=1"
end

CLEAN.include 'tmp', 'pkg', 'lib/sassc/libsass.{so,bundle}', 'ext/libsass/VERSION',
              'ext/*.{o,so,bundle}', 'ext/Makefile'

desc "Run all tests"
task test: 'compile:libsass' do
  $LOAD_PATH.unshift('lib', 'test')
  Dir.glob('./test/**/*_test.rb') { |f| require f }
end
