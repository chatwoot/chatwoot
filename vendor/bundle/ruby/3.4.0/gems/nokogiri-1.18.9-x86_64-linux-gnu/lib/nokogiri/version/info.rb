# frozen_string_literal: true

require "singleton"
require "shellwords"

module Nokogiri
  class VersionInfo # :nodoc:
    include Singleton

    def jruby?
      ::JRUBY_VERSION if ::RUBY_PLATFORM == "java"
    end

    def windows?
      ::RUBY_PLATFORM =~ /mingw|mswin/
    end

    def ruby_minor
      Gem::Version.new(::RUBY_VERSION).segments[0..1].join(".")
    end

    def engine
      defined?(::RUBY_ENGINE) ? ::RUBY_ENGINE : "mri"
    end

    def loaded_libxml_version
      Gem::Version.new(Nokogiri::LIBXML_LOADED_VERSION
        .scan(/^(\d+)(\d\d)(\d\d)(?!\d)/).first
        .collect(&:to_i)
        .join("."))
    end

    def compiled_libxml_version
      Gem::Version.new(Nokogiri::LIBXML_COMPILED_VERSION)
    end

    def loaded_libxslt_version
      Gem::Version.new(Nokogiri::LIBXSLT_LOADED_VERSION
        .scan(/^(\d+)(\d\d)(\d\d)(?!\d)/).first
        .collect(&:to_i)
        .join("."))
    end

    def compiled_libxslt_version
      Gem::Version.new(Nokogiri::LIBXSLT_COMPILED_VERSION)
    end

    def libxml2?
      defined?(Nokogiri::LIBXML_COMPILED_VERSION)
    end

    def libxml2_has_iconv?
      defined?(Nokogiri::LIBXML_ICONV_ENABLED) && Nokogiri::LIBXML_ICONV_ENABLED
    end

    def libxslt_has_datetime?
      defined?(Nokogiri::LIBXSLT_DATETIME_ENABLED) && Nokogiri::LIBXSLT_DATETIME_ENABLED
    end

    def libxml2_using_packaged?
      libxml2? && Nokogiri::PACKAGED_LIBRARIES
    end

    def libxml2_using_system?
      libxml2? && !libxml2_using_packaged?
    end

    def libxml2_precompiled?
      libxml2_using_packaged? && Nokogiri::PRECOMPILED_LIBRARIES
    end

    def warnings
      warnings = []

      if libxml2?
        if compiled_libxml_version != loaded_libxml_version
          warnings << "Nokogiri was built against libxml version #{compiled_libxml_version}, but has dynamically loaded #{loaded_libxml_version}"
        end

        if compiled_libxslt_version != loaded_libxslt_version
          warnings << "Nokogiri was built against libxslt version #{compiled_libxslt_version}, but has dynamically loaded #{loaded_libxslt_version}"
        end
      end

      warnings
    end

    def to_hash
      header_directory = File.expand_path(File.join(File.dirname(__FILE__), "../../../ext/nokogiri"))

      {}.tap do |vi|
        vi["warnings"] = []
        vi["nokogiri"] = {}.tap do |nokogiri|
          nokogiri["version"] = Nokogiri::VERSION

          unless jruby?
            #  enable gems to build against Nokogiri with the following in their extconf.rb:
            #
            #    append_cflags(Nokogiri::VERSION_INFO["nokogiri"]["cppflags"])
            #    append_ldflags(Nokogiri::VERSION_INFO["nokogiri"]["ldflags"])
            #
            #  though, this won't work on all platform and versions of Ruby, and won't be supported
            #  forever, see https://github.com/sparklemotion/nokogiri/discussions/2746 for context.
            #
            cppflags = ["-I#{header_directory.shellescape}"]
            ldflags = []

            if libxml2_using_packaged?
              cppflags << "-I#{File.join(header_directory, "include").shellescape}"
              cppflags << "-I#{File.join(header_directory, "include/libxml2").shellescape}"
            end

            if windows?
              # on windows, third party libraries that wish to link against nokogiri
              # should link against nokogiri.so to resolve symbols. see #2167
              lib_directory = File.expand_path(File.join(File.dirname(__FILE__), "../#{ruby_minor}"))
              unless File.exist?(lib_directory)
                lib_directory = File.expand_path(File.join(File.dirname(__FILE__), ".."))
              end
              ldflags << "-L#{lib_directory.shellescape}"
              ldflags << "-l:nokogiri.so"
            end

            nokogiri["cppflags"] = cppflags
            nokogiri["ldflags"] = ldflags
          end
        end
        vi["ruby"] = {}.tap do |ruby|
          ruby["version"] = ::RUBY_VERSION
          ruby["platform"] = ::RUBY_PLATFORM
          ruby["gem_platform"] = ::Gem::Platform.local.to_s
          ruby["description"] = ::RUBY_DESCRIPTION
          ruby["engine"] = engine
          ruby["jruby"] = jruby? if jruby?
        end

        if libxml2?
          vi["libxml"] = {}.tap do |libxml|
            if libxml2_using_packaged?
              libxml["source"] = "packaged"
              libxml["precompiled"] = libxml2_precompiled?
              libxml["patches"] = Nokogiri::LIBXML2_PATCHES
            else
              libxml["source"] = "system"
            end
            libxml["memory_management"] = Nokogiri::LIBXML_MEMORY_MANAGEMENT
            libxml["iconv_enabled"] = libxml2_has_iconv?
            libxml["compiled"] = compiled_libxml_version.to_s
            libxml["loaded"] = loaded_libxml_version.to_s
          end

          vi["libxslt"] = {}.tap do |libxslt|
            if libxml2_using_packaged?
              libxslt["source"] = "packaged"
              libxslt["precompiled"] = libxml2_precompiled?
              libxslt["patches"] = Nokogiri::LIBXSLT_PATCHES
            else
              libxslt["source"] = "system"
            end
            libxslt["datetime_enabled"] = libxslt_has_datetime?
            libxslt["compiled"] = compiled_libxslt_version.to_s
            libxslt["loaded"] = loaded_libxslt_version.to_s
          end

          vi["warnings"] = warnings
        end

        if defined?(Nokogiri::OTHER_LIBRARY_VERSIONS)
          # see extconf for how this string is assembled: "lib1name:lib1version,lib2name:lib2version"
          vi["other_libraries"] = Hash[*Nokogiri::OTHER_LIBRARY_VERSIONS.split(/[,:]/)]
        elsif jruby?
          vi["other_libraries"] = {}.tap do |ol|
            Nokogiri::JAR_DEPENDENCIES.each do |k, v|
              ol[k] = v
            end
          end
        end
      end
    end

    def to_markdown
      require "yaml"
      "# Nokogiri (#{Nokogiri::VERSION})\n" +
        YAML.dump(to_hash).each_line.map { |line| "    #{line}" }.join
    end

    instance.warnings.each do |warning|
      warn "WARNING: #{warning}"
    end
  end

  # :nodoc:
  def self.uses_libxml?(requirement = nil)
    return false unless VersionInfo.instance.libxml2?
    return true unless requirement

    Gem::Requirement.new(requirement).satisfied_by?(VersionInfo.instance.loaded_libxml_version)
  end

  # :nodoc:
  def self.uses_gumbo?
    uses_libxml? # TODO: replace with Gumbo functionality
  end

  # :nodoc:
  def self.jruby?
    VersionInfo.instance.jruby?
  end

  # :nodoc:
  def self.libxml2_patches
    if VersionInfo.instance.libxml2_using_packaged?
      Nokogiri::VERSION_INFO["libxml"]["patches"]
    else
      []
    end
  end

  require_relative "../jruby/dependencies" if Nokogiri.jruby?
  require_relative "../extension"

  # Detailed version info about Nokogiri and the installed extension dependencies.
  VERSION_INFO = VersionInfo.instance.to_hash
end
