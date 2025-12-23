# -*- rake -*-

require 'rbconfig'
require 'pathname'
require 'tmpdir'
require 'rake/extensiontask'
require 'rake/clean'
require 'rspec/core/rake_task'
require 'bundler'
require 'bundler/gem_helper'

# Build directory constants
BASEDIR = Pathname( __FILE__ ).dirname
SPECDIR = BASEDIR + 'spec'
LIBDIR  = BASEDIR + 'lib'
EXTDIR  = BASEDIR + 'ext'
PKGDIR  = BASEDIR + 'pkg'
TMPDIR  = BASEDIR + 'tmp'
TESTDIR = BASEDIR + "tmp_test_*"

DLEXT   = RbConfig::CONFIG['DLEXT']
EXT     = LIBDIR + "pg_ext.#{DLEXT}"

GEMSPEC = 'pg.gemspec'

CLEAN.include( TESTDIR.to_s )
CLEAN.include( PKGDIR.to_s, TMPDIR.to_s )
CLEAN.include "lib/*/libpq.dll"
CLEAN.include "lib/pg_ext.*"
CLEAN.include "lib/pg/postgresql_lib_path.rb"

load 'Rakefile.cross'

Bundler::GemHelper.install_tasks
$gem_spec = Bundler.load_gemspec(GEMSPEC)

desc "Turn on warnings and debugging in the build."
task :maint do
	ENV['MAINTAINER_MODE'] = 'yes'
end

# Rake-compiler task
Rake::ExtensionTask.new do |ext|
	ext.name           = 'pg_ext'
	ext.gem_spec       = $gem_spec
	ext.ext_dir        = 'ext'
	ext.lib_dir        = 'lib'
	ext.source_pattern = "*.{c,h}"
	ext.cross_compile  = true
	ext.cross_platform = CrossLibraries.map(&:for_platform)

	ext.cross_config_options += CrossLibraries.map do |lib|
		{
			lib.for_platform => [
				"--enable-windows-cross",
				"--with-pg-include=#{lib.static_postgresql_incdir}",
				"--with-pg-lib=#{lib.static_postgresql_libdir}",
				# libpq-fe.h resides in src/interfaces/libpq/ before make install
				"--with-opt-include=#{lib.static_postgresql_libdir}",
			]
		}
	end

	# Add libpq.dll to windows binary gemspec
	ext.cross_compiling do |spec|
		spec.files << "lib/#{spec.platform}/libpq.dll"
	end
end

RSpec::Core::RakeTask.new(:spec).rspec_opts = "--profile -cfdoc"
task :test => :spec

# Use the fivefish formatter for docs generated from development checkout
require 'rdoc/task'

RDoc::Task.new( 'docs' ) do |rdoc|
	rdoc.options = $gem_spec.rdoc_options
	rdoc.rdoc_files = $gem_spec.extra_rdoc_files
	rdoc.generator = :fivefish
	rdoc.rdoc_dir = 'doc'
end

desc "Build the source gem #{$gem_spec.full_name}.gem into the pkg directory"
task :gem => :build

task :clobber do
	puts "Stop any Postmaster instances that remain after testing."
	require_relative 'spec/helpers'
	PG::TestingHelpers.stop_existing_postmasters()
end

desc "Update list of server error codes"
task :update_error_codes do
	URL_ERRORCODES_TXT = "http://git.postgresql.org/gitweb/?p=postgresql.git;a=blob_plain;f=src/backend/utils/errcodes.txt;hb=refs/tags/REL_15_0"

	ERRORCODES_TXT = "ext/errorcodes.txt"
	sh "wget #{URL_ERRORCODES_TXT.inspect} -O #{ERRORCODES_TXT.inspect} || curl #{URL_ERRORCODES_TXT.inspect} -o #{ERRORCODES_TXT.inspect}"

	ruby 'ext/errorcodes.rb', 'ext/errorcodes.txt', 'ext/errorcodes.def'
end

file 'ext/pg_errors.c' => ['ext/errorcodes.def'] do
	# trigger compilation of changed errorcodes.def
	touch 'ext/pg_errors.c'
end

desc "Translate readme"
task :translate do
  cd "translation" do
    # po4a's lexer might change, so record its version for reference
    sh "LANG=C po4a --version > .po4a-version"

    sh "po4a po4a.cfg"
  end
end
