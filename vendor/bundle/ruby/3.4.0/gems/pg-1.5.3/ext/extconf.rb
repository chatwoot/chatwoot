require 'pp'
require 'mkmf'


if ENV['MAINTAINER_MODE']
	$stderr.puts "Maintainer mode enabled."
	$CFLAGS <<
		' -Wall' <<
		' -ggdb' <<
		' -DDEBUG' <<
		' -pedantic'
end

if pgdir = with_config( 'pg' )
	ENV['PATH'] = "#{pgdir}/bin" + File::PATH_SEPARATOR + ENV['PATH']
end

if enable_config("gvl-unlock", true)
	$defs.push( "-DENABLE_GVL_UNLOCK" )
	$stderr.puts "Calling libpq with GVL unlocked"
else
	$stderr.puts "Calling libpq with GVL locked"
end

if enable_config("windows-cross")
	# Avoid dependency to external libgcc.dll on x86-mingw32
	$LDFLAGS << " -static-libgcc"
	# Don't use pg_config for cross build, but --with-pg-* path options
	dir_config 'pg'

else
	# Native build

	pgconfig = with_config('pg-config') ||
		with_config('pg_config') ||
		find_executable('pg_config')

	if pgconfig && pgconfig != 'ignore'
		$stderr.puts "Using config values from %s" % [ pgconfig ]
		incdir = IO.popen([pgconfig, "--includedir"], &:read).chomp
		libdir = IO.popen([pgconfig, "--libdir"], &:read).chomp
		dir_config 'pg', incdir, libdir

		# Windows traditionally stores DLLs beside executables, not in libdir
		dlldir = RUBY_PLATFORM=~/mingw|mswin/ ? IO.popen([pgconfig, "--bindir"], &:read).chomp : libdir

	elsif checking_for "libpq per pkg-config" do
			_cflags, ldflags, _libs = pkg_config("libpq")
			dlldir = ldflags && ldflags[/-L([^ ]+)/] && $1
		end

	else
		incdir, libdir = dir_config 'pg'
		dlldir = libdir
	end

	# Try to use runtime path linker option, even if RbConfig doesn't know about it.
	# The rpath option is usually set implicit by dir_config(), but so far not
	# on MacOS-X.
	if dlldir && RbConfig::CONFIG["RPATHFLAG"].to_s.empty?
		append_ldflags "-Wl,-rpath,#{dlldir.quote}"
	end
end

$stderr.puts "Using libpq from #{dlldir}"

File.write("postgresql_lib_path.rb", <<-EOT)
module PG
	POSTGRESQL_LIB_PATH = #{dlldir.inspect}
end
EOT
$INSTALLFILES = {
	"./postgresql_lib_path.rb" => "$(RUBYLIBDIR)/pg/"
}

if RUBY_VERSION >= '2.3.0' && /solaris/ =~ RUBY_PLATFORM
	append_cppflags( '-D__EXTENSIONS__' )
end

begin
	find_header( 'libpq-fe.h' ) or abort "Can't find the 'libpq-fe.h header"
	find_header( 'libpq/libpq-fs.h' ) or abort "Can't find the 'libpq/libpq-fs.h header"
	find_header( 'pg_config_manual.h' ) or abort "Can't find the 'pg_config_manual.h' header"

	abort "Can't find the PostgreSQL client library (libpq)" unless
		have_library( 'pq', 'PQconnectdb', ['libpq-fe.h'] ) ||
		have_library( 'libpq', 'PQconnectdb', ['libpq-fe.h'] ) ||
		have_library( 'ms/libpq', 'PQconnectdb', ['libpq-fe.h'] )

rescue SystemExit
	install_text = case RUBY_PLATFORM
	when /linux/
	<<-EOT
Please install libpq or postgresql client package like so:
  sudo apt install libpq-dev
  sudo yum install postgresql-devel
  sudo zypper in postgresql-devel
  sudo pacman -S postgresql-libs
EOT
	when /darwin/
	<<-EOT
Please install libpq or postgresql client package like so:
  brew install libpq
EOT
	when /mingw/
	<<-EOT
Please install libpq or postgresql client package like so:
  ridk exec sh -c "pacman -S ${MINGW_PACKAGE_PREFIX}-postgresql"
EOT
	else
	<<-EOT
Please install libpq or postgresql client package.
EOT
	end

	$stderr.puts <<-EOT
*****************************************************************************

Unable to find PostgreSQL client library.

#{install_text}
or try again with:
  gem install pg -- --with-pg-config=/path/to/pg_config

or set library paths manually with:
  gem install pg -- --with-pg-include=/path/to/libpq-fe.h/ --with-pg-lib=/path/to/libpq.so/

EOT
	raise
end

if /mingw/ =~ RUBY_PLATFORM && RbConfig::MAKEFILE_CONFIG['CC'] =~ /gcc/
	# Work around: https://sourceware.org/bugzilla/show_bug.cgi?id=22504
	checking_for "workaround gcc version with link issue" do
		`#{RbConfig::MAKEFILE_CONFIG['CC']} --version`.chomp =~ /\s(\d+)\.\d+\.\d+(\s|$)/ &&
			$1.to_i >= 6 &&
			have_library(':libpq.lib') # Prefer linking to libpq.lib over libpq.dll if available
	end
end

have_func 'PQconninfo', 'libpq-fe.h' or
	abort "Your PostgreSQL is too old. Either install an older version " +
	      "of this gem or upgrade your database to at least PostgreSQL-9.3."
# optional headers/functions
have_func 'PQsslAttribute', 'libpq-fe.h' # since PostgreSQL-9.5
have_func 'PQresultVerboseErrorMessage', 'libpq-fe.h' # since PostgreSQL-9.6
have_func 'PQencryptPasswordConn', 'libpq-fe.h' # since PostgreSQL-10
have_func 'PQresultMemorySize', 'libpq-fe.h' # since PostgreSQL-12
have_func 'PQenterPipelineMode', 'libpq-fe.h' do |src| # since PostgreSQL-14
  # Ensure header files fit as well
  src + " int con(){ return PGRES_PIPELINE_SYNC; }"
end
have_func 'timegm'
have_func 'rb_gc_adjust_memory_usage' # since ruby-2.4
have_func 'rb_gc_mark_movable' # since ruby-2.7
have_func 'rb_io_wait' # since ruby-3.0

# unistd.h confilicts with ruby/win32.h when cross compiling for win32 and ruby 1.9.1
have_header 'unistd.h'
have_header 'inttypes.h'
have_header('ruby/fiber/scheduler.h') if RUBY_PLATFORM=~/mingw|mswin/

checking_for "C99 variable length arrays" do
	$defs.push( "-DHAVE_VARIABLE_LENGTH_ARRAYS" ) if try_compile('void test_vla(int l){ int vla[l]; }')
end

create_header()
create_makefile( "pg_ext" )

