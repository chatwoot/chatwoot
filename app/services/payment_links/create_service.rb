class PaymentLinks::CreateService
  PROVIDERS = %w[payzah tap].freeze

  attr_reader :conversation, :user, :amount, :currency, :provider, :account

  def initialize(conversation:, amount:, currency:, provider: nil, user: Current.user)
    @conversation = conversation
    @user = user
    @amount = amount
    @currency = currency
    @account = conversation.account
    @provider = provider || detect_default_provider
  end

  def perform
    validate_provider_configuration!

    payment_link = create_payment_link_record

    begin
      response = call_provider_api(payment_link.external_payment_id)
      update_with_provider_data(payment_link, response)
      message = create_message(payment_link)
      payment_link.update!(message: message)

      Rails.logger.info("Payment link created successfully: #{payment_link.id} via #{provider}")
      payment_link
    rescue StandardError => e
      Rails.logger.error("Payment link creation failed: #{e.message}")
      payment_link.mark_as_failed!({ error: e.message, failed_at: Time.current.iso8601 })
      raise
    end
  end

  private

  def detect_default_provider
    return 'tap' if account.tap_settings&.tap_configured?
    return 'payzah' if account.payzah_settings&.payzah_configured?

    nil
  end

  def validate_provider_configuration!
    raise ArgumentError, 'No payment provider is configured for this account.' if provider.blank?
    raise ArgumentError, "Invalid provider: #{provider}" unless PROVIDERS.include?(provider)

    case provider
    when 'payzah'
      validate_payzah_configuration!
    when 'tap'
      validate_tap_configuration!
    end
  end

  def validate_payzah_configuration!
    return if account.payzah_settings&.payzah_configured?

    raise ArgumentError, 'Payzah is not configured for this account. ' \
                         'Please configure Payzah API key in Settings → Integrations → Payzah.'
  end

  def validate_tap_configuration!
    return if account.tap_settings&.tap_configured?

    raise ArgumentError, 'Tap is not configured for this account. ' \
                         'Please configure Tap secret key in Settings → Integrations → Tap.'
  end

  def create_payment_link_record
    PaymentLink.create!(
      account: account,
      conversation: conversation,
      contact: conversation.contact,
      created_by: user,
      amount: amount,
      currency: currency,
      status: :initiated,
      provider: provider,
      payment_url: '',
      payload: {
        customer_data: customer_data,
        initiated_at: Time.current.iso8601
      }
    )
  end

  def call_provider_api(reference_id)
    case provider
    when 'payzah'
      call_payzah_api(reference_id)
    when 'tap'
      call_tap_api(reference_id)
    end
  end

  def call_payzah_api(trackid)
    Payzah::CreatePaymentLinkService.new(
      trackid: trackid,
      amount: amount,
      currency: currency,
      customer: customer_data,
      api_key: account.payzah_settings.api_key
    ).perform
  end

  def call_tap_api(reference_id)
    Tap::CreateInvoiceService.new(
      reference_id: reference_id,
      amount: amount,
      currency: currency,
      customer: customer_data,
      secret_key: account.tap_settings.secret_key
    ).perform
  end

  def update_with_provider_data(payment_link, response)
    case provider
    when 'payzah'
      update_with_payzah_data(payment_link, response)
    when 'tap'
      update_with_tap_data(payment_link, response)
    end
  end

  def update_with_payzah_data(payment_link, payzah_response)
    payment_link.update!(
      payment_url: payzah_response['transit_url'],
      status: :pending,
      payload: payment_link.payload.merge(
        payzah_payment_id: payzah_response['PaymentID'],
        payzah_response: payzah_response.to_h,
        payzah_called_at: Time.current.iso8601
      )
    )
  end

  def update_with_tap_data(payment_link, tap_response)
    payment_link.update!(
      payment_url: tap_response['url'],
      status: :pending,
      payload: payment_link.payload.merge(
        tap_invoice_id: tap_response['id'],
        tap_response: tap_response.to_h,
        tap_called_at: Time.current.iso8601
      )
    )
  end

  def create_message(payment_link)
    Messages::MessageBuilder.new(user, conversation, {
                                   content: "Amount: #{amount} #{currency}\n\nClick here to pay: #{payment_link.payment_url}",
                                   message_type: :outgoing,
                                   content_type: :payment_link,
                                   private: false,
                                   content_attributes: {
                                     data: {
                                       payment_link_id: payment_link.id,
                                       external_payment_id: payment_link.external_payment_id,
                                       payment_url: payment_link.payment_url,
                                       amount: amount,
                                       currency: currency,
                                       status: payment_link.status,
                                       provider: provider
                                     }
                                   }
                                 }).perform
  end

  def customer_data
    @customer_data ||= {
      name: conversation.contact&.name,
      email: conversation.contact&.email,
      phone: conversation.contact&.phone_number
    }.compact
  end
end
