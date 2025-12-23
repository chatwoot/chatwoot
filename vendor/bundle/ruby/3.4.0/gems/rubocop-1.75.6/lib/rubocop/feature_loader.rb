# frozen_string_literal: true

module RuboCop
  # This class handles loading files (a.k.a. features in Ruby) specified
  # by `--require` command line option and `require` directive in the config.
  #
  # Normally, the given string is directly passed to `require`. If a string
  # beginning with `.` is given, it is assumed to be relative to the given
  # directory.
  #
  # If a string containing `-` is given, it will be used as is, but if we
  # cannot find the file to load, we will replace `-` with `/` and try it
  # again as when Bundler loads gems.
  #
  # @api private
  class FeatureLoader
    class << self
      # @param [String] config_directory_path
      # @param [String] feature
      def load(config_directory_path:, feature:)
        new(config_directory_path: config_directory_path, feature: feature).load
      end
    end

    # @param [String] config_directory_path
    # @param [String] feature
    def initialize(config_directory_path:, feature:)
      @config_directory_path = config_directory_path
      @feature = feature
    end

    def load
      # Don't use `::Kernel.require(target)` to prevent the following error:
      # https://github.com/rubocop/rubocop/issues/10893
      require(target)
    rescue ::LoadError => e
      raise if e.path != target

      begin
        # Don't use `::Kernel.require(target)` to prevent the following error:
        # https://github.com/rubocop/rubocop/issues/10893
        require(namespaced_target)
      rescue ::LoadError => error_for_namespaced_target
        # NOTE: This wrap is necessary due to JRuby 9.3.4.0 incompatibility:
        # https://github.com/jruby/jruby/issues/7316
        raise LoadError, e if error_for_namespaced_target.path == namespaced_target

        raise error_for_namespaced_target
      end
    end

    private

    # @return [String]
    def namespaced_feature
      @feature.tr('-', '/')
    end

    # @return [String]
    def namespaced_target
      if relative?
        relative(namespaced_feature)
      else
        namespaced_feature
      end
    end

    # @param [String]
    # @return [String]
    def relative(feature)
      ::File.join(@config_directory_path, feature)
    end

    # @return [Boolean]
    def relative?
      @feature.start_with?('.')
    end

    # @param [LoadError] error
    # @return [Boolean]
    def seems_cannot_load_such_file_error?(error)
      error.path == target
    end

    # @return [String]
    def target
      if relative?
        relative(@feature)
      else
        @feature
      end
    end
  end
end
