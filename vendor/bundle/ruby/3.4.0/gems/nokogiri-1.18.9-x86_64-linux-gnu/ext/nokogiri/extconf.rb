# frozen_string_literal: true

# rubocop:disable Style/GlobalVars

ENV["RC_ARCHS"] = "" if RUBY_PLATFORM.include?("darwin")

require "mkmf"
require "rbconfig"
require "fileutils"
require "shellwords"
require "pathname"

# helpful constants
PACKAGE_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
REQUIRED_LIBXML_VERSION = "2.9.2"
RECOMMENDED_LIBXML_VERSION = "2.12.0"

REQUIRED_MINI_PORTILE_VERSION = "~> 2.8.2" # keep this version in sync with the one in the gemspec
REQUIRED_PKG_CONFIG_VERSION = "~> 1.1"

# Keep track of what versions of what libraries we build against
OTHER_LIBRARY_VERSIONS = {}

NOKOGIRI_HELP_MESSAGE = <<~HELP
  USAGE: ruby #{$PROGRAM_NAME} [options]

    Flags that are always valid:

      --use-system-libraries
      --enable-system-libraries
          Use system libraries instead of building and using the packaged libraries.

      --disable-system-libraries
          Use the packaged libraries, and ignore the system libraries. This is the default on most
          platforms, and overrides `--use-system-libraries` and the environment variable
          `NOKOGIRI_USE_SYSTEM_LIBRARIES`.

      --disable-clean
          Do not clean out intermediate files after successful build.

      --prevent-strip
          Take steps to prevent stripping the symbol table and debugging info from the shared
          library, potentially overriding RbConfig's CFLAGS/LDFLAGS/DLDFLAGS.


    Flags only used when using system libraries:

      General:

        --with-opt-dir=DIRECTORY
            Look for headers and libraries in DIRECTORY.

        --with-opt-lib=DIRECTORY
            Look for libraries in DIRECTORY.

        --with-opt-include=DIRECTORY
            Look for headers in DIRECTORY.


      Related to libxml2:

        --with-xml2-dir=DIRECTORY
            Look for xml2 headers and library in DIRECTORY.

        --with-xml2-lib=DIRECTORY
            Look for xml2 library in DIRECTORY.

        --with-xml2-include=DIRECTORY
            Look for xml2 headers in DIRECTORY.

        --with-xml2-source-dir=DIRECTORY
            (dev only) Build libxml2 from the source code in DIRECTORY

        --disable-xml2-legacy
            Do not build libxml2 with zlib, liblzma, or HTTP support. This will become the default
            in a future version of Nokogiri.


      Related to libxslt:

        --with-xslt-dir=DIRECTORY
            Look for xslt headers and library in DIRECTORY.

        --with-xslt-lib=DIRECTORY
            Look for xslt library in DIRECTORY.

        --with-xslt-include=DIRECTORY
            Look for xslt headers in DIRECTORY.

        --with-xslt-source-dir=DIRECTORY
            (dev only) Build libxslt from the source code in DIRECTORY


      Related to libexslt:

        --with-exslt-dir=DIRECTORY
            Look for exslt headers and library in DIRECTORY.

        --with-exslt-lib=DIRECTORY
            Look for exslt library in DIRECTORY.

        --with-exslt-include=DIRECTORY
            Look for exslt headers in DIRECTORY.


      Related to iconv:

        --with-iconv-dir=DIRECTORY
            Look for iconv headers and library in DIRECTORY.

        --with-iconv-lib=DIRECTORY
            Look for iconv library in DIRECTORY.

        --with-iconv-include=DIRECTORY
            Look for iconv headers in DIRECTORY.


      Related to zlib (ignored if `--disable-xml2-legacy` is used):

        --with-zlib-dir=DIRECTORY
            Look for zlib headers and library in DIRECTORY.

        --with-zlib-lib=DIRECTORY
            Look for zlib library in DIRECTORY.

        --with-zlib-include=DIRECTORY
            Look for zlib headers in DIRECTORY.


    Flags only used when building and using the packaged libraries:

      --disable-static
          Do not statically link packaged libraries, instead use shared libraries.

      --enable-cross-build
          Enable cross-build mode. (You probably do not want to set this manually.)


    Environment variables used:

      NOKOGIRI_USE_SYSTEM_LIBRARIES
          Equivalent to `--enable-system-libraries` when set, even if nil or blank.

      AR
          Use this path to invoke the library archiver instead of `RbConfig::CONFIG['AR']`

      CC
          Use this path to invoke the compiler instead of `RbConfig::CONFIG['CC']`

      CPPFLAGS
          If this string is accepted by the C preprocessor, add it to the flags passed to the C preprocessor

      CFLAGS
          If this string is accepted by the compiler, add it to the flags passed to the compiler

      LD
          Use this path to invoke the linker instead of `RbConfig::CONFIG['LD']`

      LDFLAGS
          If this string is accepted by the linker, add it to the flags passed to the linker

      LIBS
          Add this string to the flags passed to the linker
HELP

#
#  utility functions
#
def config_clean?
  enable_config("clean", true)
end

def config_static?
  default_static = !truffle?
  enable_config("static", default_static)
end

def config_cross_build?
  enable_config("cross-build")
end

def config_system_libraries?
  enable_config("system-libraries", ENV.key?("NOKOGIRI_USE_SYSTEM_LIBRARIES")) do |_, default|
    arg_config("--use-system-libraries", default)
  end
end

def config_with_xml2_legacy?
  enable_config("xml2-legacy", true)
end

def windows?
  RbConfig::CONFIG["target_os"].match?(/mingw|mswin/)
end

def solaris?
  RbConfig::CONFIG["target_os"].include?("solaris")
end

def darwin?
  RbConfig::CONFIG["target_os"].include?("darwin")
end

def openbsd?
  RbConfig::CONFIG["target_os"].include?("openbsd")
end

def aix?
  RbConfig::CONFIG["target_os"].include?("aix")
end

def unix?
  !(windows? || solaris? || darwin?)
end

def nix?
  ENV.key?("NIX_CC")
end

def truffle?
  RUBY_ENGINE == "truffleruby"
end

def concat_flags(*args)
  args.compact.join(" ")
end

def local_have_library(lib, func = nil, headers = nil)
  have_library(lib, func, headers) || have_library("lib#{lib}", func, headers)
end

def zlib_source(version_string)
  # As of 2022-12, I'm starting to see failed downloads often enough from zlib.net that I want to
  # change the default to github.
  if ENV["NOKOGIRI_USE_CANONICAL_ZLIB_SOURCE"]
    "https://zlib.net/fossils/zlib-#{version_string}.tar.gz"
  else
    "https://github.com/madler/zlib/releases/download/v#{version_string}/zlib-#{version_string}.tar.gz"
  end
end

def gnome_source
  "https://download.gnome.org"
end

LOCAL_PACKAGE_RESPONSE = Object.new
def LOCAL_PACKAGE_RESPONSE.%(package)
  package ? "yes: #{package}" : "no"
end

# wrapper around MakeMakefil#pkg_config and the PKGConfig gem
def try_package_configuration(pc)
  unless ENV.key?("NOKOGIRI_TEST_PKG_CONFIG_GEM")
    # try MakeMakefile#pkg_config, which uses the system utility `pkg-config`.
    return if checking_for("#{pc} using `pkg_config`", LOCAL_PACKAGE_RESPONSE) do
      pkg_config(pc)
    end
  end

  # `pkg-config` probably isn't installed, which appears to be the case for lots of freebsd systems.
  # let's fall back to the pkg-config gem, which knows how to parse .pc files, and wrap it with the
  # same logic as MakeMakefile#pkg_config
  begin
    require "rubygems"
    gem("pkg-config", REQUIRED_PKG_CONFIG_VERSION)
    require "pkg-config"

    checking_for("#{pc} using pkg-config gem version #{PKGConfig::VERSION}", LOCAL_PACKAGE_RESPONSE) do
      if PKGConfig.have_package(pc)
        cflags  = PKGConfig.cflags(pc)
        ldflags = PKGConfig.libs_only_L(pc)
        libs    = PKGConfig.libs_only_l(pc)

        Logging.message("pkg-config gem found package configuration for %s\n", pc)
        Logging.message("cflags: %s\nldflags: %s\nlibs: %s\n\n", cflags, ldflags, libs)

        [cflags, ldflags, libs]
      end
    end
  rescue LoadError
    message("Please install either the `pkg-config` utility or the `pkg-config` rubygem.\n")
  end
end

# set up mkmf to link against the library if we can find it
def have_package_configuration(opt: nil, pc: nil, lib:, func:, headers:)
  if opt
    dir_config(opt)
    dir_config("opt")
  end

  # see if we have enough path info to do this without trying any harder
  unless ENV.key?("NOKOGIRI_TEST_PKG_CONFIG")
    return true if local_have_library(lib, func, headers)
  end

  try_package_configuration(pc) if pc

  # verify that we can compile and link against the library
  local_have_library(lib, func, headers)
end

def ensure_package_configuration(opt: nil, pc: nil, lib:, func:, headers:)
  have_package_configuration(opt: opt, pc: pc, lib: lib, func: func, headers: headers) ||
    abort_could_not_find_library(lib)
end

def ensure_func(func, headers = nil)
  have_func(func, headers) || abort_could_not_find_library(func)
end

def preserving_globals
  values = [$arg_config, $INCFLAGS, $CFLAGS, $CPPFLAGS, $LDFLAGS, $DLDFLAGS, $LIBPATH, $libs].map(&:dup)
  yield
ensure
  $arg_config, $INCFLAGS, $CFLAGS, $CPPFLAGS, $LDFLAGS, $DLDFLAGS, $LIBPATH, $libs = values
end

def abort_could_not_find_library(lib)
  callers = caller(1..2).join("\n")
  abort("-----\n#{callers}\n#{lib} is missing. Please locate mkmf.log to investigate how it is failing.\n-----")
end

def chdir_for_build(&block)
  # When using rake-compiler-dock on Windows, the underlying Virtualbox shared
  # folders don't support symlinks, but libiconv expects it for a build on
  # Linux. We work around this limitation by using the temp dir for cooking.
  build_dir = /mingw|mswin|cygwin/.match?(ENV["RCD_HOST_RUBY_PLATFORM"].to_s) ? "/tmp" : "."
  Dir.chdir(build_dir, &block)
end

def sh_export_path(path)
  # because libxslt 1.1.29 configure.in uses AC_PATH_TOOL which treats ":"
  # as a $PATH separator, we need to convert windows paths from
  #
  #   C:/path/to/foo
  #
  # to
  #
  #   /C/path/to/foo
  #
  # which is sh-compatible, in order to find things properly during
  # configuration
  return path unless windows?

  match = Regexp.new("^([A-Z]):(/.*)").match(path)
  if match && match.length == 3
    return File.join("/", match[1], match[2])
  end

  path
end

def libflag_to_filename(ldflag)
  case ldflag
  when /\A-l(.+)/
    "lib#{Regexp.last_match(1)}.#{$LIBEXT}"
  end
end

def have_libxml_headers?(version = nil)
  source = if version.nil?
    <<~SRC
      #include <libxml/xmlversion.h>
    SRC
  else
    version_int = format("%d%2.2d%2.2d", *version.split("."))
    <<~SRC
      #include <libxml/xmlversion.h>
      #if LIBXML_VERSION < #{version_int}
      #  error libxml2 is older than #{version}
      #endif
    SRC
  end

  try_cpp(source)
end

def try_link_iconv(using = nil)
  checking_for(using ? "iconv using #{using}" : "iconv") do
    ["", "-liconv"].any? do |opt|
      preserving_globals do
        yield if block_given?

        try_link(<<~SRC, opt)
          #include <stdlib.h>
          #include <iconv.h>
          int main(void)
          {
              iconv_t cd = iconv_open("", "");
              iconv(cd, NULL, NULL, NULL, NULL);
              return EXIT_SUCCESS;
          }
        SRC
      end
    end
  end
end

def iconv_configure_flags
  # give --with-iconv-dir and --with-opt-dir first priority
  ["iconv", "opt"].each do |target|
    config = preserving_globals { dir_config(target) }
    next unless config.any? && try_link_iconv("--with-#{target}-* flags") { dir_config(target) }

    idirs, ldirs = config.map do |dirs|
      Array(dirs).flat_map do |dir|
        dir.split(File::PATH_SEPARATOR)
      end if dirs
    end

    return [
      "--with-iconv=yes",
      *("CPPFLAGS=#{idirs.map { |dir| "-I" + dir }.join(" ")}" if idirs),
      *("LDFLAGS=#{ldirs.map { |dir| "-L" + dir }.join(" ")}" if ldirs),
    ]
  end

  if try_link_iconv
    return ["--with-iconv=yes"]
  end

  config = preserving_globals { pkg_config("libiconv") }
  if config && try_link_iconv("pkg-config libiconv") { pkg_config("libiconv") }
    cflags, ldflags, libs = config

    return [
      "--with-iconv=yes",
      "CPPFLAGS=#{cflags}",
      "LDFLAGS=#{ldflags}",
      "LIBS=#{libs}",
    ]
  end

  abort_could_not_find_library("libiconv")
end

def process_recipe(name, version, static_p, cross_p, cacheable_p = true)
  require "rubygems"
  gem("mini_portile2", REQUIRED_MINI_PORTILE_VERSION) # gemspec is not respected at install time
  require "mini_portile2"
  message("Using mini_portile version #{MiniPortile::VERSION}\n")

  unless ["libxml2", "libxslt"].include?(name)
    OTHER_LIBRARY_VERSIONS[name] = version
  end

  MiniPortile.new(name, version).tap do |recipe|
    def recipe.port_path
      "#{@target}/#{RUBY_PLATFORM}/#{@name}/#{@version}"
    end

    # We use 'host' to set compiler prefix for cross-compiling. Prefer host_alias over host. And
    # prefer i686 (what external dev tools use) to i386 (what ruby's configure.ac emits).
    recipe.host = RbConfig::CONFIG["host_alias"].empty? ? RbConfig::CONFIG["host"] : RbConfig::CONFIG["host_alias"]
    recipe.host = recipe.host.gsub("i386", "i686")

    recipe.target = File.join(PACKAGE_ROOT_DIR, "ports") if cacheable_p
    recipe.configure_options << "--libdir=#{File.join(recipe.path, "lib")}"

    yield recipe

    env = Hash.new do |hash, key|
      hash[key] = (ENV[key]).to_s
    end

    recipe.configure_options.flatten!

    recipe.configure_options.delete_if do |option|
      case option
      when /\A(\w+)=(.*)\z/
        env[Regexp.last_match(1)] = if env.key?(Regexp.last_match(1))
          concat_flags(env[Regexp.last_match(1)], Regexp.last_match(2))
        else
          Regexp.last_match(2)
        end
        true
      else
        false
      end
    end

    if static_p
      recipe.configure_options += [
        "--disable-shared",
        "--enable-static",
      ]
      env["CFLAGS"] = concat_flags(env["CFLAGS"], "-fPIC")
    else
      recipe.configure_options += [
        "--enable-shared",
        "--disable-static",
      ]
    end

    if cross_p
      recipe.configure_options += [
        "--target=#{recipe.host}",
        "--host=#{recipe.host}",
      ]
    end

    if RbConfig::CONFIG["target_cpu"] == "universal"
      ["CFLAGS", "LDFLAGS"].each do |key|
        unless env[key].include?("-arch")
          env[key] = concat_flags(env[key], RbConfig::CONFIG["ARCH_FLAG"])
        end
      end
    end

    recipe.configure_options += env.map do |key, value|
      "#{key}=#{value.strip}"
    end

    checkpoint = "#{recipe.target}/#{recipe.name}-#{recipe.version}-#{RUBY_PLATFORM}.installed"
    if File.exist?(checkpoint) && !recipe.source_directory
      message("Building Nokogiri with a packaged version of #{name}-#{version}.\n")
    else
      message(<<~EOM)
        ---------- IMPORTANT NOTICE ----------
        Building Nokogiri with a packaged version of #{name}-#{version}.
        Configuration options: #{recipe.configure_options.shelljoin}
      EOM

      unless recipe.patch_files.empty?
        message("The following patches are being applied:\n")

        recipe.patch_files.each do |patch|
          message(format("  - %s\n", File.basename(patch)))
        end
      end

      message(<<~EOM) if name != "libgumbo"

        The Nokogiri maintainers intend to provide timely security updates, but if
        this is a concern for you and want to use your OS/distro system library
        instead, then abort this installation process and install nokogiri as
        instructed at:

          https://nokogiri.org/tutorials/installing_nokogiri.html#installing-using-standard-system-libraries

      EOM

      message(<<~EOM) if name == "libxml2"
        Note, however, that nokogiri cannot guarantee compatibility with every
        version of libxml2 that may be provided by OS/package vendors.

      EOM

      chdir_for_build { recipe.cook }
      FileUtils.touch(checkpoint)
    end
    recipe.activate
  end
end

def copy_packaged_libraries_headers(to_path:, from_recipes:)
  FileUtils.rm_rf(to_path, secure: true)
  FileUtils.mkdir(to_path)
  from_recipes.each do |recipe|
    FileUtils.cp_r(Dir[File.join(recipe.path, "include/*")], to_path)
  end
end

def do_help
  print(NOKOGIRI_HELP_MESSAGE)
  exit!(0)
end

def do_clean
  root = Pathname(PACKAGE_ROOT_DIR)
  pwd  = Pathname(Dir.pwd)

  # Skip if this is a development work tree
  unless (root + ".git").exist?
    message("Cleaning files only used during build.\n")

    # (root + 'tmp') cannot be removed at this stage because
    # nokogiri.so is yet to be copied to lib.

    # clean the ports build directory
    Pathname.glob(pwd.join("tmp", "*", "ports")) do |dir|
      FileUtils.rm_rf(dir, verbose: true)
    end

    if config_static?
      # ports installation can be safely removed if statically linked.
      FileUtils.rm_rf(root + "ports", verbose: true)
    else
      FileUtils.rm_rf(root + "ports" + "archives", verbose: true)
    end
  end

  exit!(0)
end

# In ruby 3.2, symbol resolution changed on Darwin, to introduce the `-bundle_loader` flag to
# resolve symbols against the ruby binary.
#
# This makes it challenging to build a single extension that works with both a ruby with
# `--enable-shared` and one with `--disable-shared. To work around that, we choose to add
# `-flat_namespace` to the link line (later in this file).
#
# The `-flat_namespace` line introduces its own behavior change, which is that (similar to on
# Linux), any symbols in the extension that are exported may now be resolved by shared libraries
# loaded by the Ruby process. Specifically, that means that libxml2 and libxslt, which are
# statically linked into the nokogiri bundle, will resolve (at runtime) to a system libxml2 loaded
# by Ruby on Darwin. And it appears that often Ruby on Darwin does indeed load the system libxml2,
# and that messes with our assumptions about whether we're running with a patched libxml2 or a
# vanilla libxml2.
#
# We choose to use `-load_hidden` in this case to prevent exporting those symbols from libxml2 and
# libxslt, which ensures that they will be resolved to the static libraries in the bundle. In other
# words, when we use `load_hidden`, what happens in the extension stays in the extension.
#
# See https://github.com/rake-compiler/rake-compiler-dock/issues/87 for more info.
#
# Anyway, this method is the logical bit to tell us when to turn on these workarounds.
def needs_darwin_linker_hack
  config_cross_build? &&
    darwin? &&
    Gem::Requirement.new("~> 3.2").satisfied_by?(Gem::Version.new(RbConfig::CONFIG["ruby_version"].split("+").first))
end

#
#  main
#
do_help if arg_config("--help")
do_clean if arg_config("--clean")

if openbsd? && !config_system_libraries?
  unless %x(#{ENV["CC"] || "/usr/bin/cc"} -v 2>&1).include?("clang")
    (ENV["CC"] ||= find_executable("egcc")) ||
      abort("Please install gcc 4.9+ from ports using `pkg_add -v gcc`")
  end
  append_cppflags "-I/usr/local/include"
end

if ENV["AR"]
  RbConfig::CONFIG["AR"] = RbConfig::MAKEFILE_CONFIG["AR"] = ENV["AR"]
end

if ENV["CC"]
  RbConfig::CONFIG["CC"] = RbConfig::MAKEFILE_CONFIG["CC"] = ENV["CC"]
end

if ENV["LD"]
  RbConfig::CONFIG["LD"] = RbConfig::MAKEFILE_CONFIG["LD"] = ENV["LD"]
end

# use same toolchain for libxml and libxslt
ENV["AR"] = RbConfig::CONFIG["AR"]
ENV["CC"] = RbConfig::CONFIG["CC"]
ENV["LD"] = RbConfig::CONFIG["LD"]

if arg_config("--prevent-strip")
  old_cflags = $CFLAGS.split.join(" ")
  old_ldflags = $LDFLAGS.split.join(" ")
  old_dldflags = $DLDFLAGS.split.join(" ")
  $CFLAGS = $CFLAGS.split.reject { |flag| flag == "-s" }.join(" ")
  $LDFLAGS = $LDFLAGS.split.reject { |flag| flag == "-s" }.join(" ")
  $DLDFLAGS = $DLDFLAGS.split.reject { |flag| flag == "-s" }.join(" ")
  puts "Prevent stripping by removing '-s' from $CFLAGS" if old_cflags != $CFLAGS
  puts "Prevent stripping by removing '-s' from $LDFLAGS" if old_ldflags != $LDFLAGS
  puts "Prevent stripping by removing '-s' from $DLDFLAGS" if old_dldflags != $DLDFLAGS
end

# adopt environment config
append_cflags(ENV["CFLAGS"]) unless ENV["CFLAGS"].nil?
append_cppflags(ENV["CPPFLAGS"]) unless ENV["CPPFLAGS"].nil?
append_ldflags(ENV["LDFLAGS"]) unless ENV["LDFLAGS"].nil?
$LIBS = concat_flags($LIBS, ENV["LIBS"])

# libgumbo uses C90/C99 features, see #2302
append_cflags(["-std=c99", "-Wno-declaration-after-statement"])

# gumbo html5 serialization is slower with O3, let's make sure we use O2
append_cflags("-O2")

# always include debugging information
append_cflags("-g")

# we use at least one inline function in the C extension
append_cflags("-Winline")

# good to have no matter what Ruby was compiled with
append_cflags("-Wmissing-noreturn")

# check integer loss of precision. this flag won't generally work until Ruby 3.4.
# see https://bugs.ruby-lang.org/issues/20507
append_cflags("-Wconversion")

# handle clang variations, see #1101
if darwin?
  append_cflags("-Wno-error=unused-command-line-argument-hard-error-in-future")
  append_cflags("-Wno-unknown-warning-option")
end

# these tend to be noisy, but on occasion useful during development
# append_cflags(["-Wcast-qual", "-Wwrite-strings"])

# Add SDK-specific include path for macOS and brew versions before v2.2.12 (2020-04-08) [#1851, #1801]
macos_mojave_sdk_include_path = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/libxml2"
if config_system_libraries? && darwin? && Dir.exist?(macos_mojave_sdk_include_path) && !nix?
  append_cppflags("-I#{macos_mojave_sdk_include_path}")
end

# Work around a character escaping bug in MSYS by passing an arbitrary double-quoted parameter to gcc.
# See https://sourceforge.net/p/mingw/bugs/2142
append_cppflags(' "-Idummypath"') if windows?

if config_system_libraries?
  message "Building nokogiri using system libraries.\n"
  if config_with_xml2_legacy?
    ensure_package_configuration(
      opt: "zlib",
      pc: "zlib",
      lib: "z",
      headers: "zlib.h",
      func: "gzdopen",
    )
  end
  ensure_package_configuration(
    opt: "xml2",
    pc: "libxml-2.0",
    lib: "xml2",
    headers: "libxml/parser.h",
    func: "xmlParseDoc",
  )
  ensure_package_configuration(
    opt: "xslt",
    pc: "libxslt",
    lib: "xslt",
    headers: "libxslt/xslt.h",
    func: "xsltParseStylesheetDoc",
  )
  ensure_package_configuration(
    opt: "exslt",
    pc: "libexslt",
    lib: "exslt",
    headers: "libexslt/exslt.h",
    func: "exsltFuncRegister",
  )

  have_libxml_headers?(REQUIRED_LIBXML_VERSION) ||
    abort("ERROR: libxml2 version #{REQUIRED_LIBXML_VERSION} or later is required!")
  have_libxml_headers?(RECOMMENDED_LIBXML_VERSION) ||
    warn("WARNING: libxml2 version #{RECOMMENDED_LIBXML_VERSION} or later is highly recommended, but proceeding anyway.")

else
  message "Building nokogiri using packaged libraries.\n"

  static_p = config_static?
  message "Static linking is #{static_p ? "enabled" : "disabled"}.\n"

  cross_build_p = config_cross_build?
  message "Cross build is #{cross_build_p ? "enabled" : "disabled"}.\n"

  if needs_darwin_linker_hack
    append_ldflags("-Wl,-flat_namespace")
  end

  require "yaml"
  dependencies = YAML.load_file(File.join(PACKAGE_ROOT_DIR, "dependencies.yml"))

  dir_config("zlib") if config_with_xml2_legacy?

  if cross_build_p || windows?
    if config_with_xml2_legacy?
      zlib_recipe = process_recipe("zlib", dependencies["zlib"]["version"], static_p, cross_build_p) do |recipe|
        recipe.files = [{
          url: zlib_source(recipe.version),
          sha256: dependencies["zlib"]["sha256"],
        }]
        if windows?
          class << recipe
            attr_accessor :cross_build_p

            def configure
              Dir.chdir(work_path) do
                mk = File.read("win32/Makefile.gcc")
                File.open("win32/Makefile.gcc", "wb") do |f|
                  f.puts "BINARY_PATH = #{path}/bin"
                  f.puts "LIBRARY_PATH = #{path}/lib"
                  f.puts "INCLUDE_PATH = #{path}/include"
                  mk.sub!(/^PREFIX\s*=\s*$/, "PREFIX = #{host}-") if cross_build_p
                  f.puts mk
                end
              end
            end

            def configured?
              Dir.chdir(work_path) do
                !!(File.read("win32/Makefile.gcc") =~ /^BINARY_PATH/)
              end
            end

            def compile
              execute("compile", "make -f win32/Makefile.gcc")
            end

            def install
              execute("install", "make -f win32/Makefile.gcc install")
            end
          end
          recipe.cross_build_p = cross_build_p
        else
          class << recipe
            def configure
              env = {}
              env["CFLAGS"] = concat_flags(ENV["CFLAGS"], "-fPIC", "-g")
              env["CHOST"] = host
              execute("configure", ["./configure", "--static", configure_prefix], { env: env })
              if darwin?
                # needed as of zlib 1.2.13
                Dir.chdir(work_path) do
                  makefile = File.read("Makefile").gsub(/^AR=.*$/, "AR=#{host}-libtool")
                  File.open("Makefile", "w") { |m| m.write(makefile) }
                end
              end
            end
          end
        end
      end
    end

    unless unix?
      libiconv_recipe = process_recipe(
        "libiconv",
        dependencies["libiconv"]["version"],
        static_p,
        cross_build_p,
      ) do |recipe|
        recipe.files = [{
          url: "https://ftp.gnu.org/pub/gnu/libiconv/#{recipe.name}-#{recipe.version}.tar.gz",
          sha256: dependencies["libiconv"]["sha256"],
        }]

        # The libiconv configure script doesn't accept "arm64" host string but "aarch64"
        recipe.host = recipe.host.gsub("arm64-apple-darwin", "aarch64-apple-darwin")

        cflags = concat_flags(ENV["CFLAGS"], "-O2", "-g")

        recipe.configure_options += [
          "--disable-dependency-tracking",
          "CPPFLAGS=-Wall",
          "CFLAGS=#{cflags}",
          "CXXFLAGS=#{cflags}",
          "LDFLAGS=",
        ]
      end
    end
  elsif darwin? && !have_header("iconv.h")
    abort(<<~EOM.chomp)
      -----
      The file "iconv.h" is missing in your build environment,
      which means you haven't installed Xcode Command Line Tools properly.

      To install Command Line Tools, try running `xcode-select --install` on
      terminal and follow the instructions.  If it fails, open Xcode.app,
      select from the menu "Xcode" - "Open Developer Tool" - "More Developer
      Tools" to open the developer site, download the installer for your OS
      version and run it.
      -----
    EOM
  end

  if zlib_recipe
    append_cppflags("-I#{zlib_recipe.path}/include")
    $LIBPATH = ["#{zlib_recipe.path}/lib"] | $LIBPATH
    ensure_package_configuration(
      opt: "zlib",
      pc: "zlib",
      lib: "z",
      headers: "zlib.h",
      func: "gzdopen",
    )
  end

  if libiconv_recipe
    append_cppflags("-I#{libiconv_recipe.path}/include")
    $LIBPATH = ["#{libiconv_recipe.path}/lib"] | $LIBPATH
    ensure_package_configuration(
      opt: "iconv",
      pc: "iconv",
      lib: "iconv",
      headers: "iconv.h",
      func: "iconv_open",
    )
  end

  libxml2_recipe = process_recipe("libxml2", dependencies["libxml2"]["version"], static_p, cross_build_p) do |recipe|
    source_dir = arg_config("--with-xml2-source-dir")
    if source_dir
      recipe.source_directory = source_dir
    else
      minor_version = Gem::Version.new(recipe.version).segments.take(2).join(".")
      recipe.files = [{
        url: "#{gnome_source}/sources/libxml2/#{minor_version}/#{recipe.name}-#{recipe.version}.tar.xz",
        sha256: dependencies["libxml2"]["sha256"],
      }]
      recipe.patch_files = Dir[File.join(PACKAGE_ROOT_DIR, "patches", "libxml2", "*.patch")].sort
    end

    cppflags = concat_flags(ENV["CPPFLAGS"])
    cflags = concat_flags(ENV["CFLAGS"], "-O2", "-g")

    if cross_build_p
      cppflags = concat_flags(cppflags, "-DNOKOGIRI_PRECOMPILED_LIBRARIES")
    end

    if config_with_xml2_legacy?
      recipe.configure_options << "--with-legacy"
    end

    if zlib_recipe
      recipe.configure_options << "--with-zlib=#{zlib_recipe.path}"
    end

    if libiconv_recipe
      recipe.configure_options << "--with-iconv=#{libiconv_recipe.path}"
    else
      recipe.configure_options += iconv_configure_flags
    end

    if darwin? && !cross_build_p
      recipe.configure_options << "RANLIB=/usr/bin/ranlib" unless ENV.key?("RANLIB")
      recipe.configure_options << "AR=/usr/bin/ar" unless ENV.key?("AR")
    end

    if windows?
      cflags = concat_flags(cflags, "-ULIBXML_STATIC", "-DIN_LIBXML")
    end

    recipe.configure_options << if source_dir
      "--config-cache"
    else
      "--disable-dependency-tracking"
    end

    recipe.configure_options += [
      "--without-python",
      "--without-readline",
      "--with-c14n",
      "--with-debug",
      "--with-threads",
      "CPPFLAGS=#{cppflags}",
      "CFLAGS=#{cflags}",
    ]
  end

  libxslt_recipe = process_recipe("libxslt", dependencies["libxslt"]["version"], static_p, cross_build_p) do |recipe|
    source_dir = arg_config("--with-xslt-source-dir")
    if source_dir
      recipe.source_directory = source_dir
    else
      minor_version = Gem::Version.new(recipe.version).segments.take(2).join(".")
      recipe.files = [{
        url: "#{gnome_source}/sources/libxslt/#{minor_version}/#{recipe.name}-#{recipe.version}.tar.xz",
        sha256: dependencies["libxslt"]["sha256"],
      }]
      recipe.patch_files = Dir[File.join(PACKAGE_ROOT_DIR, "patches", "libxslt", "*.patch")].sort
    end

    cflags = concat_flags(ENV["CFLAGS"], "-O2", "-g")

    if darwin? && !cross_build_p
      recipe.configure_options << "RANLIB=/usr/bin/ranlib" unless ENV.key?("RANLIB")
      recipe.configure_options << "AR=/usr/bin/ar" unless ENV.key?("AR")
    end

    if windows?
      cflags = concat_flags(cflags, "-ULIBXSLT_STATIC", "-DIN_LIBXSLT")
      cflags = concat_flags(cflags, "-ULIBEXSLT_STATIC", "-DIN_LIBEXSLT")
    end

    recipe.configure_options << if source_dir
      "--config-cache"
    else
      "--disable-dependency-tracking"
    end

    recipe.configure_options += [
      "--without-python",
      "--without-crypto",
      "--with-debug",
      "--with-libxml-prefix=#{sh_export_path(libxml2_recipe.path)}",
      "CFLAGS=#{cflags}",
    ]
  end

  append_cppflags("-DNOKOGIRI_PACKAGED_LIBRARIES")
  append_cppflags("-DNOKOGIRI_PRECOMPILED_LIBRARIES") if cross_build_p

  $libs = $libs.shellsplit.tap do |libs|
    [libxml2_recipe, libxslt_recipe].each do |recipe|
      libname = recipe.name[/\Alib(.+)\z/, 1]
      config_basename = "#{libname}-config"
      File.join(recipe.path, "bin", config_basename).tap do |config|
        # call config scripts explicit with 'sh' for compat with Windows
        cflags = %x(sh #{config} --cflags).strip
        message("#{config_basename} cflags: #{cflags}\n")
        $CPPFLAGS = concat_flags(cflags, $CPPFLAGS) # prepend

        %x(sh #{config} --libs).strip.shellsplit.each do |arg|
          case arg
          when /\A-L(.+)\z/
            # Prioritize ports' directories
            $LIBPATH = if Regexp.last_match(1).start_with?(PACKAGE_ROOT_DIR + "/")
              [Regexp.last_match(1)] | $LIBPATH
            else
              $LIBPATH | [Regexp.last_match(1)]
            end
          when /\A-l./
            libs.unshift(arg)
          else
            $LDFLAGS << " " << arg.shellescape
          end
        end
      end

      patches_string = recipe.patch_files.map { |path| File.basename(path) }.join(" ")
      append_cppflags(%[-DNOKOGIRI_#{recipe.name.upcase}_PATCHES="\\"#{patches_string}\\""])

      case libname
      when "xml2"
        # xslt-config --libs or pkg-config libxslt --libs does not include
        # -llzma, so we need to add it manually when linking statically.
        if static_p && preserving_globals { local_have_library("lzma") }
          # Add it at the end; GH #988
          libs << "-llzma"
        end
      when "xslt"
        # xslt-config does not have a flag to emit options including
        # -lexslt, so add it manually.
        libs.unshift("-lexslt")
      end
    end
  end.shelljoin

  if static_p
    static_archive_ld_flag = needs_darwin_linker_hack ? ["-load_hidden"] : []
    $libs = $libs.shellsplit.map do |arg|
      case arg
      when "-lxml2"
        static_archive_ld_flag + [File.join(libxml2_recipe.path, "lib", libflag_to_filename(arg))]
      when "-lxslt", "-lexslt"
        static_archive_ld_flag + [File.join(libxslt_recipe.path, "lib", libflag_to_filename(arg))]
      else
        arg
      end
    end.flatten.shelljoin
  end

  ensure_func("xmlParseDoc", "libxml/parser.h")
  ensure_func("xsltParseStylesheetDoc", "libxslt/xslt.h")
  ensure_func("exsltFuncRegister", "libexslt/exslt.h")
end

if arg_config("--gumbo-dev")
  message("DEV MODE ENABLED: build libgumbo as packaged source")
  ext_dir = File.dirname(__FILE__)
  Dir.chdir(ext_dir) do
    $srcs = Dir["*.c", "../../gumbo-parser/src/*.c"]
    $hdrs = Dir["*.h", "../../gumbo-parser/src/*.h"]
  end
  $INCFLAGS << " -I$(srcdir)/../../gumbo-parser/src"
  $VPATH << "$(srcdir)/../../gumbo-parser/src"
  find_header("nokogiri_gumbo.h") || abort("nokogiri_gumbo.h not found")
else
  libgumbo_recipe = process_recipe("libgumbo", "1.0.0-nokogiri", static_p, cross_build_p, false) do |recipe|
    recipe.configure_options = []

    class << recipe
      def downloaded?
        true
      end

      def extract
        target = File.join(tmp_path, "gumbo-parser")
        output("Copying gumbo-parser files into #{target}...")
        FileUtils.mkdir_p(target)
        FileUtils.cp(Dir.glob(File.join(PACKAGE_ROOT_DIR, "gumbo-parser/src/*")), target)
      end

      def configured?
        true
      end

      def install
        lib_dir = File.join(port_path, "lib")
        inc_dir = File.join(port_path, "include")
        FileUtils.mkdir_p([lib_dir, inc_dir])
        FileUtils.cp(File.join(work_path, "libgumbo.a"), lib_dir)
        FileUtils.cp(Dir.glob(File.join(work_path, "*.h")), inc_dir)
      end

      def compile
        cflags = concat_flags(ENV["CFLAGS"], "-fPIC", "-O2", "-g")

        env = { "CC" => gcc_cmd, "CFLAGS" => cflags }
        if config_cross_build?
          if host.include?("darwin")
            env["AR"] = "#{host}-libtool"
            env["ARFLAGS"] = "-o"
          else
            env["AR"] = "#{host}-ar"
          end
          env["RANLIB"] = "#{host}-ranlib"
          if windows?
            concat_flags(env["CFLAGS"], "-D_RUBY_UCRT")
          end
        end

        execute("compile", make_cmd, { env: env })
      end
    end
  end
  append_cppflags("-I#{File.join(libgumbo_recipe.path, "include")}")
  $libs = $libs + " " + File.join(libgumbo_recipe.path, "lib", "libgumbo.a")
  $LIBPATH = $LIBPATH | [File.join(libgumbo_recipe.path, "lib")]
  ensure_func("gumbo_parse_with_options", "nokogiri_gumbo.h")
end

have_func("xmlCtxtSetOptions") # introduced in libxml2 2.13.0
have_func("xmlCtxtGetOptions") # introduced in libxml2 2.14.0
have_func("xmlSwitchEncodingName") # introduced in libxml2 2.13.0
have_func("rb_category_warning") # introduced in Ruby 3.0 but had trouble resolving this symbol in truffleruby

other_library_versions_string = OTHER_LIBRARY_VERSIONS.map { |k, v| [k, v].join(":") }.join(",")
append_cppflags(%[-DNOKOGIRI_OTHER_LIBRARY_VERSIONS="\\"#{other_library_versions_string}\\""])

unless config_system_libraries?
  if cross_build_p
    # When precompiling native gems, copy packaged libraries' headers to ext/nokogiri/include
    # These are packaged up by the cross-compiling callback in the ExtensionTask
    copy_packaged_libraries_headers(
      to_path: File.join(PACKAGE_ROOT_DIR, "ext/nokogiri/include"),
      from_recipes: [libxml2_recipe, libxslt_recipe],
    )
  else
    # When compiling during installation, install packaged libraries' header files into ext/nokogiri/include
    copy_packaged_libraries_headers(
      to_path: "include",
      from_recipes: [libxml2_recipe, libxslt_recipe],
    )
    $INSTALLFILES << ["include/**/*.h", "$(rubylibdir)"]
  end
end

create_makefile("nokogiri/nokogiri")

if config_clean?
  # Do not clean if run in a development work tree.
  File.open("Makefile", "at") do |mk|
    mk.print(<<~EOF)

      all: clean-ports
      clean-ports: $(TARGET_SO)
      \t-$(Q)$(RUBY) $(srcdir)/extconf.rb --clean --#{static_p ? "enable" : "disable"}-static
    EOF
  end
end

# rubocop:enable Style/GlobalVars
