# frozen_string_literal: true

require "erb"

module AnnotateRb
  # Raised when a configuration file is not found.
  class ConfigNotFoundError < StandardError
  end

  class ConfigLoader
    class << self
      def load_config
        config_path = ConfigFinder.find_project_dotfile

        if config_path
          load_yaml_configuration(config_path)
        else
          {}
        end
      end

      # Method from Rubocop::ConfigLoader
      def load_yaml_configuration(absolute_path)
        file_contents = read_file(absolute_path)
        yaml_code = ERB.new(file_contents).result

        hash = yaml_safe_load(yaml_code, absolute_path) || {}

        # TODO: Print config if debug flag/option is set

        raise(TypeError, "Malformed configuration in #{absolute_path}") unless hash.is_a?(Hash)

        hash
      end

      # Read the specified file, or exit with a friendly, concise message on
      # stderr. Care is taken to use the standard OS exit code for a "file not
      # found" error.
      #
      # Method from Rubocop::ConfigLoader
      def read_file(absolute_path)
        File.read(absolute_path, encoding: Encoding::UTF_8)
      rescue Errno::ENOENT
        raise ConfigNotFoundError, "Configuration file not found: #{absolute_path}"
      end

      # Method from Rubocop::ConfigLoader
      def yaml_safe_load(yaml_code, filename)
        yaml_safe_load!(yaml_code, filename)
      rescue
        if defined?(::SafeYAML)
          raise "SafeYAML is unmaintained, no longer needed and should be removed"
        end

        raise
      end

      # Method from Rubocop::ConfigLoader
      def yaml_safe_load!(yaml_code, filename)
        YAML.safe_load(
          yaml_code, permitted_classes: [Regexp, Symbol], aliases: true, filename: filename, symbolize_names: true
        )
      end
    end
  end
end
