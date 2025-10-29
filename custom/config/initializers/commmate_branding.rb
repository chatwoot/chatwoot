# frozen_string_literal: true

# Load CommMate branding configuration
module CommMate
  class Branding
    class << self
      def config
        @config ||= load_config
      end

      private

      def load_config
        custom_config_path = Rails.root.join('custom/config/branding.yml')
        if File.exist?(custom_config_path)
          YAML.load_file(custom_config_path).with_indifferent_access
        else
          {}
        end
      end
    end
  end
end

# Override default branding
Rails.application.config.after_initialize do
  branding = CommMate::Branding.config

  next unless branding.present?

  # Set app name
  ENV['APP_NAME'] = branding[:app_name] if branding[:app_name]

  # Set brand colors
  ENV['BRAND_PRIMARY_COLOR'] = branding.dig(:colors, :primary) if branding.dig(:colors, :primary)

  # Set URLs
  ENV['BRAND_URL'] = branding[:website] if branding[:website]
  ENV['SUPPORT_EMAIL'] = branding[:support_email] if branding[:support_email]
end

