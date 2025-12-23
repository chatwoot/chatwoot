# frozen_string_literal: true

require_relative "libdatadog/version"

module Libdatadog
  # This should only be used for debugging/logging
  def self.available_binaries
    File.directory?(vendor_directory) ? (Dir.entries(vendor_directory) - [".", ".."]) : []
  end

  def self.pkgconfig_folder(pkgconfig_file_name = "datadog_profiling_with_rpath.pc")
    current_platform = self.current_platform

    return unless available_binaries.include?(current_platform)

    pkgconfig_file = Dir.glob("#{vendor_directory}/#{current_platform}/**/#{pkgconfig_file_name}").first

    return unless pkgconfig_file

    File.absolute_path(File.dirname(pkgconfig_file))
  end

  private_class_method def self.vendor_directory
    ENV["LIBDATADOG_VENDOR_OVERRIDE"] || "#{__dir__}/../vendor/libdatadog-#{Libdatadog::LIB_VERSION}/"
  end

  def self.current_platform
    platform = Gem::Platform.local.to_s

    if platform.end_with?("-gnu")
      # In some cases on Linux with glibc the platform includes a -gnu suffix. We normalize it to not have the suffix.
      #
      # Note: This should be platform = platform.delete_suffix("-gnu") but it doesn't work on legacy Rubies; once
      # dd-trace-rb 2.0 is out we can simplify this.
      #
      platform = platform[0..-5]
    end

    if RbConfig::CONFIG["arch"].include?("-musl") && !platform.include?("-musl")
      # Fix/workaround for https://github.com/datadog/dd-trace-rb/issues/2222
      #
      # Old versions of rubygems (for instance 3.0.3) don't properly detect alternative libc implementations on Linux;
      # in particular for our case, they don't detect musl. (For reference, Rubies older than 2.7 may have shipped with
      # an affected version of rubygems).
      # In such cases, we fall back to use RbConfig::CONFIG['arch'] instead.
      #
      # Why not use RbConfig::CONFIG['arch'] always? Because Gem::Platform.local.to_s does some normalization that seemed
      # useful in the past, although part of it got removed in https://github.com/rubygems/rubygems/pull/5852.
      # For now we only add this workaround in a specific situation where we actually know it is wrong, but in the
      # future it may be worth re-evaluating if we should move away from `Gem::Platform` altogether.
      #
      # See also https://github.com/rubygems/rubygems/pull/2922 and https://github.com/rubygems/rubygems/pull/4082

      RbConfig::CONFIG["arch"]
    else
      platform
    end
  end

  def self.path_to_crashtracking_receiver_binary
    pkgconfig_folder = self.pkgconfig_folder

    return unless pkgconfig_folder

    File.absolute_path("#{pkgconfig_folder}/../../bin/libdatadog-crashtracking-receiver")
  end

  def self.ld_library_path
    pkgconfig_folder = self.pkgconfig_folder

    return unless pkgconfig_folder

    File.absolute_path("#{pkgconfig_folder}/../")
  end
end
