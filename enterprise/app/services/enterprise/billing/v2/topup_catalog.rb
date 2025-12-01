module Enterprise::Billing::V2::TopupCatalog
  DEFAULT_TOPUPS = [
    { credits: 1000, amount: 20.0 },
    { credits: 2500, amount: 50.0 },
    { credits: 5000, amount: 100.0 },
    { credits: 10_000, amount: 200.0 }
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
