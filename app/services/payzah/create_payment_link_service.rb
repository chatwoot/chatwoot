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

  attr_reader :trackid, :amount, :currency, :language, :customer, :account

  def initialize(trackid:, amount:, currency: DEFAULT_CURRENCY, language: DEFAULT_LANGUAGE, customer: {}, account: nil)
    @trackid = trackid
    @amount = amount
    @currency = currency
    @language = language
    @customer = customer
    @account = account
  end

  def perform
    validate_params!

    response = create_payment_request
    validate_response!(response)

    extract_payment_data(response)
  end

  private

  def create_payment_request
    api_key = fetch_payzah_api_key!
    client = Payzah::ApiClient.new(api_key: api_key)
    client.create_payment(payment_params)
  rescue Payzah::ApiClient::ApiError => e
    Rails.logger.error "Payzah payment creation failed: #{e.message}"
    raise
  end

  def fetch_payzah_api_key!
    return @account.payzah_settings.api_key if @account.payzah_settings&.payzah_configured?

    raise ArgumentError, 'Payzah is not configured for this account. ' \
                         'Please configure Payzah API key in Settings → Integrations → Payzah.'
  end

  def validate_response!(response)
    raise Payzah::ApiClient::ApiError, 'Invalid response format from Payzah API' unless response.is_a?(Hash)

    unless response['status'] == true
      error_message = 'Payzah API returned unsuccessful status'
      Rails.logger.error "#{error_message}. Response: #{response.inspect}"
      raise Payzah::ApiClient::ApiError, error_message
    end

    return if response['data'].is_a?(Hash)

    raise Payzah::ApiClient::ApiError, 'Response data is missing or invalid'
  end

  def payment_params
    {
      trackid: trackid,
      amount: format_amount(amount),
      success_url: success_url,
      error_url: error_url,
      language: language,
      currency: currency,
      payment_type: PAYMENT_TYPE_ALL
    }
  end

  def format_amount(value)
    # Ensure amount is formatted as a string with 2 decimal places
    format('%.2f', value.to_f)
  end

  def extract_payment_data(response)
    data = response['data']
    payment_url = data['transit_url']
    payment_id = data['PaymentID']

    if payment_url.blank?
      error_message = 'Payment URL not found in Payzah response'
      Rails.logger.error "#{error_message}. Response: #{response.inspect}"
      raise Payzah::ApiClient::ApiError, error_message
    end

    Rails.logger.info "Payzah payment created successfully. PaymentID: #{payment_id}"

    {
      payment_url: payment_url,
      payment_id: payment_id,
      direct_url: data['direct_url'],
      gateway_url: data['PaymentUrl']
    }
  end

  def success_url
    "#{frontend_url}/api/v1/payzah/success"
  end

  def error_url
    "#{frontend_url}/api/v1/payzah/error"
  end

  def frontend_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def validate_params!
    raise ArgumentError, 'Track ID is required' if trackid.blank?
    raise ArgumentError, 'Amount is required' if amount.blank?
    raise ArgumentError, 'Amount must be positive' if amount.to_f <= 0
    raise ArgumentError, 'Currency is required' if currency.blank?
  end
end
