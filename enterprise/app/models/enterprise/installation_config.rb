module Enterprise::InstallationConfig
  DPA_SIGNING_HOST = 'app.hellosign.com'.freeze

  def self.prepended(base)
    base.validate :validate_dpa_signing_url, if: -> { name == 'CHATWOOT_DPA_SIGNING_URL' }
  end

  private

  def validate_dpa_signing_url
    return if value.nil? || (value.is_a?(String) && value.blank?)
    return if valid_dpa_signing_url?

    errors.add(:base, I18n.t('errors.installation_config.invalid_dpa_signing_url', host: DPA_SIGNING_HOST))
  end

  def valid_dpa_signing_url?
    return false unless value.is_a?(String)

    url = URI.parse(value)
    url.is_a?(URI::HTTPS) && url.host&.casecmp?(DPA_SIGNING_HOST) && url.port == 443 && url.userinfo.nil?
  rescue URI::InvalidURIError
    false
  end
end
