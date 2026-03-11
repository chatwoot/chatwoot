# frozen_string_literal: true

# lib/integrations/infinitepay/create_link_service.rb
# Creates an InfinitePay checkout link and sends it as a message in the conversation.

class Integrations::Infinitepay::CreateLinkService
  INFINITEPAY_API = 'https://api.infinitepay.io/invoices/public/checkout/links'
  TIMEOUT = 15

  def initialize(account:, conversation:, user:, amount_cents:, description:, payment_method: nil, installments: nil)
    @account = account
    @conversation = conversation
    @user = user
    @amount_cents = amount_cents
    @description = description
    @payment_method = payment_method || 'pix'
    @installments = installments
  end

  def perform
    handle = @account.custom_attributes&.dig('infinitepay_handle')
    raise ArgumentError, 'InfinitePay handle not configured for this account' if handle.blank?

    order_nsu = "chatwit-#{@account.id}-#{@conversation.id}-#{SecureRandom.hex(6)}"
    webhook_url = "#{ENV.fetch('FRONTEND_URL', 'https://chatwit.witdev.com.br')}/webhooks/infinitepay"

    contact = @conversation.contact
    payload = build_payload(handle, order_nsu, webhook_url, contact)

    response = HTTParty.post(
      INFINITEPAY_API,
      headers: { 'Content-Type' => 'application/json' },
      body: payload.to_json,
      timeout: TIMEOUT
    )

    raise "InfinitePay API error: #{response.code} - #{response.body}" unless response.success?

    checkout_url = extract_checkout_url(response)

    payment_link = PaymentLink.create!(
      account: @account,
      conversation: @conversation,
      user: @user,
      order_nsu: order_nsu,
      amount_cents: @amount_cents,
      description: @description,
      checkout_url: checkout_url,
      status: 'pending'
    )

    send_link_message(checkout_url)

    payment_link
  end

  private

  def build_payload(handle, order_nsu, webhook_url, contact)
    base_url = ENV.fetch('FRONTEND_URL', 'https://chatwit.witdev.com.br')
    redirect_url = "#{base_url}/app/accounts/#{@account.id}/conversations/#{@conversation.display_id}"

    payload = {
      handle: handle,
      order_nsu: order_nsu,
      webhook_url: webhook_url,
      redirect_url: redirect_url,
      items: [
        {
          quantity: 1,
          price: @amount_cents,
          description: @description
        }
      ]
    }

    if contact.present?
      phone = contact.phone_number.presence || contact_inbox_identifier(contact)
      payload[:customer] = {
        name: contact.name.presence || phone || 'Cliente',
        email: contact.email.presence || 'seuemail@gmail.com',
        phone_number: phone
      }.compact
    end

    payload
  end

  def contact_inbox_identifier(contact)
    contact_inbox = ContactInbox.find_by(contact_id: contact.id, inbox_id: @conversation.inbox_id)
    source_id = contact_inbox&.source_id
    return nil if source_id.blank?

    # WhatsApp source_id is the phone number
    source_id.gsub(/\D/, '').presence
  end

  def extract_checkout_url(response)
    parsed = response.parsed_response
    parsed['checkout_url'] || parsed['url'] || parsed['link']
  end

  def send_link_message(checkout_url)
    amount_formatted = format('R$ %.2f', @amount_cents / 100.0)
    content = "💰 *Link de Pagamento*\n\n#{@description}\nValor: #{amount_formatted}\n\n#{checkout_url}"

    @conversation.messages.create!(
      account: @account,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      sender: @user
    )
  end
end
