module Enterprise::Billing::TopupCatalog
  DEFAULT_TOPUPS = [
    { credits: 1000, amount: 20.0, currency: 'usd' },
    { credits: 2500, amount: 50.0, currency: 'usd' },
    { credits: 5000, amount: 100.0, currency: 'usd' },
    { credits: 10_000, amount: 200.0, currency: 'usd' }
  ].freeze

  module_function

  def options
    DEFAULT_TOPUPS
  end

  def find_option(credits)
    options.find { |opt| opt[:credits] == credits.to_i }
  end
end
