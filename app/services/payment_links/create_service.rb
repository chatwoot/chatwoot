class PaymentLinks::CreateService
  attr_reader :conversation, :user, :amount, :currency, :account

  def initialize(conversation:, amount:, currency:, user: Current.user)
    @conversation = conversation
    @user = user
    @amount = amount
    @currency = currency
    @account = conversation.account
  end

  def perform
    validate_payzah_configuration!

    payment_link = create_payment_link_record

    begin
      payzah_response = call_payzah_api(payment_link.external_payment_id)
      update_with_payzah_data(payment_link, payzah_response)
      message = create_message(payment_link)
      payment_link.update!(message: message)

      Rails.logger.info("Payment link created successfully: #{payment_link.id}")
      payment_link
    rescue StandardError => e
      Rails.logger.error("Payment link creation failed: #{e.message}")
      payment_link.mark_as_failed!({ error: e.message, failed_at: Time.current.iso8601 })
      raise
    end
  end

  private

  def validate_payzah_configuration!
    return if account.payzah_settings&.payzah_configured?

    raise ArgumentError, 'Payzah is not configured for this account. ' \
                         'Please configure Payzah API key in Settings → Integrations → Payzah.'
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
      provider: 'payzah',
      payment_url: '',
      payload: {
        customer_data: customer_data,
        initiated_at: Time.current.iso8601
      }
    )
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
                                       status: payment_link.status
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
