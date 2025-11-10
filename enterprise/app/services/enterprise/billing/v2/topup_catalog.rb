module Enterprise::Billing::V2::TopupCatalog
  DEFAULT_TOPUPS = [
    { credits: 1000, amount: 20.0 },
    { credits: 2000, amount: 40.0 },
    { credits: 3000, amount: 60.0 },
    { credits: 4000, amount: 80.0 }
  ].freeze

  module_function

  def options
    custom_options = InstallationConfig.find_by(name: 'STRIPE_TOPUP_OPTIONS')&.value
    parsed = parse_options(custom_options)
    (parsed.presence || DEFAULT_TOPUPS).sort_by { |opt| opt[:credits] }.map do |option|
      {
        credits: option[:credits],
        amount: option[:amount],
        currency: option[:currency] || 'usd'
      }
    end
  end

  def parse_options(raw)
    return [] if raw.blank?

    JSON.parse(raw, symbolize_names: true)
  rescue JSON::ParserError
    []
  end

  def find_option(credits)
    options.find { |option| option[:credits].to_i == credits.to_i }
  end
end
