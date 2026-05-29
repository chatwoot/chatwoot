class Enterprise::Billing::TrackPaymentAttributionService
  pattr_initialize [:account!, :invoice!]

  API_ENDPOINT = 'https://datafa.st/api/v1/payments'.freeze
  API_KEY_CONFIG = 'DATAFAST_API_KEY'.freeze
  ZERO_DECIMAL_CURRENCIES = %w[BIF CLP DJF GNF JPY KMF KRW MGA PYG RWF UGX VND VUV XAF XOF XPF].freeze

  def perform
    return unless trackable?

    response = HTTParty.post(
      API_ENDPOINT,
      headers: {
        'Authorization' => "Bearer #{api_key}",
        'Content-Type' => 'application/json'
      },
      body: payload.to_json,
      timeout: 5
    )

    log_failure("#{response.code} #{response.body}") unless response.success?
  rescue StandardError => e
    log_failure("#{e.class} - #{e.message}")
  end

  private

  def trackable?
    ChatwootApp.chatwoot_cloud? && [api_key, datafast_visitor_id, amount_paid, currency, transaction_id].all?(&:present?)
  end

  def payload
    {
      amount: amount,
      currency: currency.upcase,
      transaction_id: transaction_id,
      datafast_visitor_id: datafast_visitor_id,
      email: customer_email,
      name: customer_name,
      customer_id: customer_id,
      renewal: renewal?
    }.compact
  end

  def amount
    return amount_paid if ZERO_DECIMAL_CURRENCIES.include?(currency.upcase)

    amount_paid.to_f / 100
  end

  def amount_paid
    invoice_value('amount_paid')
  end

  def currency
    invoice_value('currency')
  end

  def transaction_id
    invoice_value('id')
  end

  def customer_id
    invoice_value('customer') || account.custom_attributes['stripe_customer_id']
  end

  def customer_email
    invoice_value('customer_email') || account.administrators.first&.email
  end

  def customer_name
    invoice_value('customer_name') || account.name
  end

  def renewal?
    invoice_value('billing_reason') == 'subscription_cycle'
  end

  def datafast_visitor_id
    attribution['datafast_visitor_id']
  end

  def attribution
    account.custom_attributes['billing_attribution'] || {}
  end

  def api_key
    GlobalConfigService.load(API_KEY_CONFIG, nil)
  end

  def log_failure(message)
    Rails.logger.warn("Payment attribution failed for invoice #{transaction_id}: #{message}")
  end

  def invoice_value(key)
    invoice[key]
  rescue NoMethodError
    nil
  end
end
