# frozen_string_literal: true

# CommMate Version Configuration
# Loads version information for CommMate branding in admin console

module CommMate
  class Version
    class << self
      def load_config
        config_path = Rails.root.join('custom/config/commmate_version.yml')
        return default_config unless File.exist?(config_path)

        YAML.safe_load(File.read(config_path)).with_indifferent_access
      rescue StandardError => e
        Rails.logger.warn "Failed to load CommMate version config: #{e.message}"
        default_config
      end

      def default_config
        {
          commmate_version: '4.8.0',
          base_chatwoot_version: '4.8.0'
        }
      end
    end
  end
end

# Load version configuration
version_config = CommMate::Version.load_config

# Define CommMate version constants
COMMMATE_VERSION = version_config[:commmate_version].freeze
COMMMATE_BASE_VERSION = version_config[:base_chatwoot_version].freeze

