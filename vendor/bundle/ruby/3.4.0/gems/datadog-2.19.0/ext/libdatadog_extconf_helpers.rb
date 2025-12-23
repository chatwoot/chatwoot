# frozen_string_literal: true

require 'rubygems'
require 'pathname'

module Datadog
  # Contains a bunch of shared helpers that get used during building of extensions that link to libdatadog
  module LibdatadogExtconfHelpers
    # Used to make sure the correct gem version gets loaded, as extconf.rb does not get run with "bundle exec" and thus
    # may see multiple libdatadog versions. See https://github.com/DataDog/dd-trace-rb/pull/2531 for the horror story.
    LIBDATADOG_VERSION = '~> 18.1.0.1.0'

    # Used as an workaround for a limitation with how dynamic linking works in environments where the datadog gem and
    # libdatadog are moved after the extension gets compiled.
    #
    # Because the libdatadog native library is installed on a non-standard system path, in order for it to be
    # found by the system dynamic linker (e.g. what takes care of dlopen(), which is used to load
    # native extensions), we need to add a "runpath" -- a list of folders to search for libdatadog.
    #
    # This runpath gets hardcoded at native library linking time. You can look at it using the `readelf` tool in
    # Linux: e.g. `readelf -d datadog_profiling_native_extension.2.7.3_x86_64-linux.so`.
    #
    # In older versions of the datadog gem, we only set as runpath an absolute path to libdatadog.
    # (This gets set automatically by the call
    # to `pkg_config('datadog_profiling_with_rpath')` in `extconf.rb`). This worked fine as long as libdatadog was **NOT**
    # moved from the folder it was present at datadog gem installation/linking time.
    #
    # Unfortunately, environments such as Heroku and AWS Elastic Beanstalk move gems around in the filesystem after
    # installation. Thus, the profiling native extension could not be loaded in these environments
    # (see https://github.com/DataDog/dd-trace-rb/issues/2067) because libdatadog could not be found.
    #
    # To workaround this issue, this method computes the **relative** path between the folder where
    # native extensions are going to be installed and the folder where libdatadog is installed, and returns it
    # to be set as an additional runpath. (Yes, you can set multiple runpath folders to be searched).
    #
    # This way, if both gems are moved together (and it turns out that they are in these environments),
    # the relative path can still be traversed to find libdatadog.
    #
    # This is incredibly awful, and it's kinda bizarre how it's not possible to just find these paths at runtime
    # and set them correctly; rather than needing to set stuff at linking-time and then praying to $deity that
    # weird moves don't happen.
    #
    # As a curiosity, `LD_LIBRARY_PATH` can be used to influence the folders that get searched but **CANNOT BE
    # SET DYNAMICALLY**, e.g. it needs to be set at the start of the process (Ruby VM) and thus it's not something
    # we could setup when doing a `require`.
    #
    def self.libdatadog_folder_relative_to_native_lib_folder(
      current_folder:,
      libdatadog_pkgconfig_folder: Libdatadog.pkgconfig_folder
    )
      return unless libdatadog_pkgconfig_folder

      native_lib_folder = "#{current_folder}/../../lib/"
      libdatadog_lib_folder = "#{libdatadog_pkgconfig_folder}/../"

      Pathname.new(libdatadog_lib_folder).relative_path_from(Pathname.new(native_lib_folder)).to_s
    end

    # In https://github.com/DataDog/dd-trace-rb/pull/3582 we got a report of a customer for which the native extension
    # only got installed into the extensions folder.
    #
    # But then this fix was not enough to fully get them moving because then they started to see the issue from
    # https://github.com/DataDog/dd-trace-rb/issues/2067 / https://github.com/DataDog/dd-trace-rb/pull/2125 :
    #
    # > Profiling was requested but is not supported, profiling disabled: There was an error loading the profiling
    # > native extension due to 'RuntimeError Failure to load datadog_profiling_native_extension.3.2.2_x86_64-linux
    # > due to libdatadog_profiling.so: cannot open shared object file: No such file or directory
    #
    # The problem is that when loading the native extension from the extensions directory, the relative rpath we add
    # with the #libdatadog_folder_relative_to_native_lib_folder helper above is not correct, we need to add a relative
    # rpath to the extensions directory.
    #
    # So how do we find the full path where the native extension is placed?
    # * From https://github.com/ruby/ruby/blob/83f02d42e0a3c39661dc99c049ab9a70ff227d5b/lib/bundler/runtime.rb#L166
    #   `extension_dirs = Dir["#{Gem.dir}/extensions/*/*/*"] + Dir["#{Gem.dir}/bundler/gems/extensions/*/*/*"]`
    #   we get that's in one of two fixed subdirectories of `Gem.dir`
    # * From https://github.com/ruby/ruby/blob/83f02d42e0a3c39661dc99c049ab9a70ff227d5b/lib/rubygems/basic_specification.rb#L111-L115
    #   we get the structure of the subdirectory (platform/extension_api_version/gem_and_version)
    #
    # Thus, `Gem.dir` of `/var/app/current/vendor/bundle/ruby/3.2.0` becomes (for instance)
    # `/var/app/current/vendor/bundle/ruby/3.2.0/extensions/x86_64-linux/3.2.0/datadog-2.0.0/` or
    # `/var/app/current/vendor/bundle/ruby/3.2.0/bundler/gems/extensions/x86_64-linux/3.2.0/datadog-2.0.0/`
    #
    # We then compute the relative path between these folders and the libdatadog folder, and use that as a relative path.
    def self.libdatadog_folder_relative_to_ruby_extensions_folders(
      gem_dir: Gem.dir,
      libdatadog_pkgconfig_folder: Libdatadog.pkgconfig_folder
    )
      return unless libdatadog_pkgconfig_folder

      # For the purposes of calculating a folder relative to the other, we don't actually NEED to fill in the
      # platform, extension_api_version and gem version. We're basically just after how many folders it is deep from
      # the Gem.dir.
      expected_ruby_extensions_folders = [
        "#{gem_dir}/extensions/platform/extension_api_version/datadog_version/",
        "#{gem_dir}/bundler/gems/extensions/platform/extension_api_version/datadog_version/",
      ]
      libdatadog_lib_folder = "#{libdatadog_pkgconfig_folder}/../"

      expected_ruby_extensions_folders.map do |folder|
        Pathname.new(libdatadog_lib_folder).relative_path_from(Pathname.new(folder)).to_s
      end
    end

    # mkmf sets $PKGCONFIG after the `pkg_config` gets used in extconf.rb. When `pkg_config` is unsuccessful, we use
    # this helper to decide if we can show more specific error message vs a generic "something went wrong".
    def self.pkg_config_missing?(command: $PKGCONFIG) # standard:disable Style/GlobalVars
      pkg_config_available = command && xsystem("#{command} --version")

      pkg_config_available != true
    end

    def self.try_loading_libdatadog
      gem 'libdatadog', LIBDATADOG_VERSION
      require 'libdatadog'
      nil
    rescue Exception => e # rubocop:disable Lint/RescueException
      if block_given?
        yield e
      else
        e
      end
    end

    def self.libdatadog_issue?
      try_loading_libdatadog { |_exception| return true }
      Libdatadog.pkgconfig_folder.nil?
    end
  end
end
