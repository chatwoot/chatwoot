# frozen_string_literal: true

gem_root = File.expand_path('..', __dir__)
libsass_dir = File.join(gem_root, 'ext', 'libsass')

if !File.directory?(libsass_dir) ||
   # '.', '..', and possibly '.git' from a failed checkout:
   Dir.entries(libsass_dir).size <= 3
  Dir.chdir(gem_root) { system('git submodule update --init') } or
    fail 'Could not fetch libsass'
end

require 'mkmf'

$CXXFLAGS << ' -std=c++11'

# Set to true when building binary gems
if enable_config('static-stdlib', false)
  $LDFLAGS << ' -static-libgcc -static-libstdc++'
end

if enable_config('march-tune-native', false)
  $CFLAGS << ' -march=native -mtune=native'
  $CXXFLAGS << ' -march=native -mtune=native'
end

# darwin nix clang doesn't support lto
# disable -lto flag for darwin + nix
# see: https://github.com/sass/sassc-ruby/issues/148
enable_lto_by_default = (Gem::Platform.local.os == "darwin" && !ENV['NIX_CC'].nil?)

if enable_config('lto', enable_lto_by_default)
  $CFLAGS << ' -flto'
  $CXXFLAGS << ' -flto'
  $LDFLAGS << ' -flto'
end

# Disable noisy compilation warnings.
$warnflags = ''
$CFLAGS.gsub!(/[\s+](-ansi|-std=[^\s]+)/, '')

dir_config 'libsass'

libsass_version = Dir.chdir(libsass_dir) do
  if File.exist?('.git')
    ver = %x[git describe --abbrev=4 --dirty --always --tags].chomp
    File.write('VERSION', ver)
    ver
  end
  File.read('VERSION').chomp if File.exist?('VERSION')
end

if libsass_version
  libsass_version_def = %Q{ -DLIBSASS_VERSION='"#{libsass_version}"'}
  $CFLAGS << libsass_version_def
  $CXXFLAGS << libsass_version_def
end

$INCFLAGS << " -I$(srcdir)/libsass/include"
$VPATH << "$(srcdir)/libsass/src"
Dir.chdir(__dir__) do
  $VPATH += Dir['libsass/src/*/'].map { |p| "$(srcdir)/#{p}" }
  $srcs = Dir['libsass/src/**/*.{c,cpp}'].sort
end

# libsass.bundle malformed object (unknown load command 7) on Mac OS X
# See https://github.com/sass/sassc-ruby/pull/174
if enable_config('strip', RbConfig::CONFIG['host_os'].downcase !~ /darwin/)
  MakeMakefile::LINK_SO << "\nstrip -x $@"
end

# Don't link libruby.
$LIBRUBYARG = nil

# Disable .def file generation for mingw, as it defines an
# `Init_libsass` export which we don't have.
MakeMakefile.send(:remove_const, :EXPORT_PREFIX)
MakeMakefile::EXPORT_PREFIX = nil

if RUBY_ENGINE == 'jruby' &&
   Gem::Version.new(RUBY_ENGINE_VERSION) < Gem::Version.new('9.2.8.0')
  # COUTFLAG is not set correctly on jruby<9.2.8.0
  # See https://github.com/jruby/jruby/issues/5749
  MakeMakefile.send(:remove_const, :COUTFLAG)
  MakeMakefile::COUTFLAG = '-o $(empty)'

  # CCDLFLAGS is not set correctly on jruby<9.2.8.0
  # See https://github.com/jruby/jruby/issues/5751
  $CXXFLAGS << ' -fPIC'
end

create_makefile 'sassc/libsass'
