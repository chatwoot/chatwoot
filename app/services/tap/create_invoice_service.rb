class Tap::CreateInvoiceService
  DEFAULT_CURRENCY = 'KWD'.freeze
  DEFAULT_LANGUAGE = 'en'.freeze

  SUPPORTED_CURRENCIES = %w[KWD USD EUR GBP SAR AED BHD QAR OMR EGP JOD].freeze

  attr_reader :reference_id, :amount, :currency, :language, :customer, :secret_key

  # rubocop:disable Metrics/ParameterLists
  def initialize(reference_id:, amount:, secret_key:, currency: DEFAULT_CURRENCY, language: DEFAULT_LANGUAGE, customer: {})
    @reference_id = reference_id
    @amount = amount
    @currency = currency
    @language = language
    @customer = customer
    @secret_key = secret_key
  end
  # rubocop:enable Metrics/ParameterLists

  def perform
    validate_params!

    response = create_invoice_request

    unless response['status'] == 'CREATED' || response['url'].present?
      error_message = response.dig('errors', 0, 'description') || response['message'] || 'Unknown error'
      raise "Tap invoice creation failed: #{error_message}"
    end

    response.with_indifferent_access
  end

  private

  def create_invoice_request
    client = Tap::ApiClient.new(secret_key: secret_key)
    client.create_invoice(invoice_params)
  rescue Tap::ApiClient::ApiError => e
    Rails.logger.error "Tap invoice creation failed: #{e.message}"
    raise
  end

  def invoice_params
    {
      mode: 'INVOICE',
      currencies: [currency.to_s.upcase],
      due: due_timestamp,
      expiry: expiry_timestamp,
      reference: {
        invoice: reference_id
      },
      customer: customer_params,
      order: order_params,
      redirect: {
        url: redirect_url
      },
      post: {
        url: webhook_url
      }
    }
  end

  def customer_params
    params = {}
    params[:first_name] = customer[:name] if customer[:name].present?
    params[:email] = customer[:email] if customer[:email].present?

    if customer[:phone].present?
      phone_data = parse_phone_number(customer[:phone])
      params[:phone] = phone_data if phone_data
    end

    params
  end

  def parse_phone_number(phone)
    return nil if phone.blank?

    cleaned = phone.to_s.gsub(/\s+/, '')

    if cleaned.start_with?('+')
      country_code = cleaned[1..3]
      number = cleaned[4..]
    else
      country_code = '965'
      number = cleaned
    end

    { country_code: country_code, number: number }
  end

  def order_params
    {
      amount: format_amount(amount),
      currency: currency.to_s.upcase,
      items: [
        {
          name: 'Payment',
          quantity: 1,
          amount: format_amount(amount)
        }
      ]
    }
  end

  def format_amount(value)
    value.to_f.round(3)
  end

  def redirect_url
    "#{base_url}/api/v1/tap/callback"
  end

  def webhook_url
    "#{base_url}/api/v1/tap/webhook"
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def due_timestamp
    ((7.days.from_now).to_i * 1000)
  end

  def expiry_timestamp
    due_timestamp
  end

  def validate_params!
    raise ArgumentError, 'Reference ID is required' if reference_id.blank?
    raise ArgumentError, 'Amount is required' if amount.blank?
    raise ArgumentError, 'Amount must be positive' if amount.to_f <= 0
    raise ArgumentError, 'Currency is required' if currency.blank?
    raise ArgumentError, "Unsupported currency: #{currency}" unless SUPPORTED_CURRENCIES.include?(currency.to_s.upcase)
    raise ArgumentError, 'Secret key is required' if secret_key.blank?
  end
end
