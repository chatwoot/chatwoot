class SetConversoLogoPathsInInstallationConfig < ActiveRecord::Migration[7.1]
  CONVERSO_LOGO_PATH = '/brand-assets/converso/logo.png'.freeze

  # Only replace stock Chatwoot branding assets so custom uploads stay untouched.
  LEGACY_LOGO_VALUES = %w[
    /brand-assets/logo.svg
    /brand-assets/logo_dark.svg
    /brand-assets/logo_thumbnail.svg
  ].freeze

  CONFIG_KEYS = %w[LOGO LOGO_DARK LOGO_THUMBNAIL].freeze

  def up
    CONFIG_KEYS.each do |name|
      config = InstallationConfig.find_by(name: name)
      next unless config

      current = config.value.to_s
      next if current.present? && LEGACY_LOGO_VALUES.exclude?(current)

      config.update!(value: CONVERSO_LOGO_PATH)
    end

    GlobalConfig.clear_cache
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
