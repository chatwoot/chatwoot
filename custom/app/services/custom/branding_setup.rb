# Installation-wide white-label branding for the fork (docs/fork/WHITE_LABEL.md,
# Layer 1). Upserts the branding InstallationConfig rows — which drive
# globalConfig.installationName in the dashboard, "Powered by" email/widget
# links, logos, and legal links — from ENV so a SaaS deploy can rebrand
# repeatably without Super Admin clicks.
#
# Why write the DB rather than rely on ENV: ConfigLoader seeds these keys from
# installation_config.yml with the "Chatwoot" defaults, and those rows shadow
# GlobalConfigService's ENV fallback; the frontend reads the DB directly via
# GlobalConfig.get. Updating InstallationConfig fires after_commit :clear_cache,
# so the GlobalConfig (Redis) cache refreshes on its own.
#
# Run: docker compose run --rm rails bundle exec rails runner "Custom::BrandingSetup.call"
class Custom::BrandingSetup
  # ENV key == InstallationConfig name (matches Chatwoot's own ENV convention in
  # GlobalConfigService). A key is only touched when its ENV var is set, so
  # partial branding leaves the remaining upstream defaults in place.
  BRANDING_KEYS = %w[
    INSTALLATION_NAME
    BRAND_NAME
    LOGO
    LOGO_DARK
    LOGO_THUMBNAIL
    BRAND_URL
    WIDGET_BRAND_URL
    TERMS_URL
    PRIVACY_URL
  ].freeze

  def self.call
    new.call
  end

  def call
    applied = BRANDING_KEYS.filter_map do |key|
      value = ENV.fetch(key, nil).presence
      next unless value

      config = InstallationConfig.find_or_initialize_by(name: key)
      next if config.value == value

      config.update!(value: value)
      key
    end

    Rails.logger.info("[BRANDING] applied #{applied.size} config change(s): #{applied.join(', ').presence || 'none'}")
    applied
  end
end
