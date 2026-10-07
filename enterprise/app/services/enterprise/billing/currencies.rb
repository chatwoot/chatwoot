# Supported billing currencies and their Stripe/locale mappings.
module Enterprise::Billing::Currencies
  DEFAULT = 'usd'.freeze

  SUPPORTED = %w[usd brl].freeze

  FEATURE_CONFIG = 'ENABLE_MULTI_CURRENCY_BILLING'.freeze

  # Account locale label (e.g. 'pt_BR') => default currency; unlisted falls back to DEFAULT.
  LOCALE_DEFAULTS = {
    'pt_BR' => 'brl'
  }.freeze

  # Billing country override per currency; absent currencies (e.g. usd) keep Stripe's default.
  COUNTRY_BY_CURRENCY = {
    'brl' => 'BR'
  }.freeze

  # Preferred Stripe/checkout locale per currency; absent currencies keep Stripe's default.
  PREFERRED_LOCALE_BY_CURRENCY = {
    'brl' => 'pt-BR'
  }.freeze

  module_function

  # Master switch for the whole multi-currency feature; off => everyone is billed in USD.
  def enabled?
    GlobalConfigService.load(FEATURE_CONFIG, 'false').to_s != 'false'
  end

  def normalize(code)
    code.to_s.strip.downcase.presence
  end

  def supported?(code)
    SUPPORTED.include?(normalize(code))
  end

  # Map arbitrary input to a supported code, else DEFAULT.
  def to_supported(code)
    supported?(code) ? normalize(code) : DEFAULT
  end

  def for_locale(locale)
    LOCALE_DEFAULTS.fetch(locale.to_s, DEFAULT)
  end

  def country_for(code)
    COUNTRY_BY_CURRENCY[to_supported(code)]
  end

  def preferred_locale_for(code)
    PREFERRED_LOCALE_BY_CURRENCY[to_supported(code)]
  end
end
