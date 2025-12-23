# frozen_string_literal: true

module Zeitwerk
  # @private
  class GemLoader < Loader
    include RealModName

    # Users should not create instances directly, the public interface is
    # `Zeitwerk::Loader.for_gem`.
    private_class_method :new

    # @private
    # @sig (String, bool) -> Zeitwerk::GemLoader
    def self.__new(root_file, namespace:, warn_on_extra_files:)
      new(root_file, namespace: namespace, warn_on_extra_files: warn_on_extra_files)
    end

    # @sig (String, bool) -> void
    def initialize(root_file, namespace:, warn_on_extra_files:)
      super()

      @tag = File.basename(root_file, ".rb")
      @tag = real_mod_name(namespace) + "-" + @tag unless namespace.equal?(Object)

      @inflector           = GemInflector.new(root_file)
      @root_file           = File.expand_path(root_file)
      @root_dir            = File.dirname(root_file)
      @warn_on_extra_files = warn_on_extra_files

      push_dir(@root_dir, namespace: namespace)
    end

    # @sig () -> void
    def setup
      warn_on_extra_files if @warn_on_extra_files
      super
    end

    private

    # @sig () -> void
    def warn_on_extra_files
      expected_namespace_dir = @root_file.delete_suffix(".rb")

      ls(@root_dir) do |basename, abspath, ftype|
        next if abspath == @root_file
        next if abspath == expected_namespace_dir

        basename_without_ext = basename.delete_suffix(".rb")
        cname = inflector.camelize(basename_without_ext, abspath).to_sym

        warn(<<~EOS)
          WARNING: Zeitwerk defines the constant #{cname} after the #{ftype}

              #{abspath}

          To prevent that, please configure the loader to ignore it:

              loader.ignore("\#{__dir__}/#{basename}")

          Otherwise, there is a flag to silence this warning:

              Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
        EOS
      end
    end
  end
end
