# frozen_string_literal: true

module AnnotateRb
  class ConfigGenerator
    class << self
      # Returns unset configuration key-value pairs as yaml.
      # Useful when a config file was generated an older version of gem and new
      #   settings get added.
      def unset_config_defaults
        user_defaults = ConfigLoader.load_config
        defaults = Options.from({}, {}).to_h

        differences = defaults.keys - user_defaults.keys
        result = defaults.slice(*differences)

        # Return empty string if no differences to avoid appending empty hash
        return "" if result.empty?

        # Generates proper YAML including the leading hyphens `---` header
        yml_content = YAML.dump(result, StringIO.new).string
        # Remove the header
        yml_content.sub("---", "")
      end

      def default_config_yml
        defaults_hash = Options.from({}, {}).to_h
        _yml_content = YAML.dump(defaults_hash, StringIO.new).string
      end
    end
  end
end
