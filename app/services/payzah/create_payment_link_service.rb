class Payzah::CreatePaymentLinkService
  # Payment type constants
  # Transit method (recommended):
  #   '3' = All payment methods including Apple Pay, debit, and credit cards
  #
  # Direct method:
  #   '1' = K-Net
  #   '2' = Credit card
  #   Default (if not specified) = K-Net
  PAYMENT_TYPE_ALL = '3'.freeze
  DEFAULT_CURRENCY = 'KWD'.freeze
  DEFAULT_LANGUAGE = 'en'.freeze

  # ISO 4217 numeric currency codes required by Payzah API
  # Note: Payzah only supports KWD currency
  CURRENCY_CODES = {
    'KWD' => 414
  }.freeze

  attr_reader :trackid, :amount, :currency, :language, :customer, :api_key

  # rubocop:disable Metrics/ParameterLists
  def initialize(trackid:, amount:, api_key:, currency: DEFAULT_CURRENCY, language: DEFAULT_LANGUAGE, customer: {})
    @trackid = trackid
    @amount = amount
    @currency = currency
    @language = language
    @customer = customer
    @api_key = api_key
  end

  def perform
    validate_params!

    response = create_payment_request

    raise "Payzah payment creation failed: #{response['message']}" unless response['status'] == true

    response['data'].with_indifferent_access
  end

  private

  def create_payment_request
    client = Payzah::ApiClient.new(api_key: api_key)
    client.create_payment(payment_params)
  rescue Payzah::ApiClient::ApiError => e
    Rails.logger.error "Payzah payment creation failed: #{e.message}"
    raise
  end

  def payment_params
    {
      trackid: trackid,
      amount: format_amount(amount),
      success_url: success_url,
      error_url: error_url,
      language: language,
      currency: numeric_currency_code,
      payment_type: PAYMENT_TYPE_ALL,
      customer_name: customer[:name],
      customer_email: customer[:email]
    }
  end

  def format_amount(value)
    value.to_f.round(3)
  end

  def success_url
    "#{base_url}/api/v1/payzah/success"
  end

  def error_url
    "#{base_url}/api/v1/payzah/error"
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def numeric_currency_code
    CURRENCY_CODES[currency.to_s.upcase] || currency
  end

  def validate_params!
    raise ArgumentError, 'Track ID is required' if trackid.blank?
    raise ArgumentError, 'Amount is required' if amount.blank?
    raise ArgumentError, 'Amount must be positive' if amount.to_f <= 0
    raise ArgumentError, 'Currency is required' if currency.blank?
    raise ArgumentError, 'Payzah only supports KWD currency' unless currency.to_s.upcase == 'KWD'
    raise ArgumentError, 'API key is required' if api_key.blank?
  end
end
