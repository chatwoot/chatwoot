# frozen_string_literal: true

# lib/integrations/infinitepay/create_link_service.rb
# Creates an InfinitePay checkout link and sends it as a message in the conversation.

class Integrations::Infinitepay::CreateLinkService
  INFINITEPAY_API = 'https://api.infinitepay.io/invoices/public/checkout/links'
  TIMEOUT = 15

  def initialize(account:, conversation:, user:, amount_cents:, description:)
    @account = account
    @conversation = conversation
    @user = user
    @amount_cents = amount_cents
    @description = description
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
    payload = {
      handle: handle,
      order_nsu: order_nsu,
      webhook_url: webhook_url,
      items: [
        {
          quantity: 1,
          price: @amount_cents,
          description: @description
        }
      ]
    }

    if contact.present?
      customer = {}
      customer[:name] = contact.name if contact.name.present?
      customer[:email] = contact.email if contact.email.present?
      customer[:phone_number] = contact.phone_number if contact.phone_number.present?
      payload[:customer] = customer if customer.present?
    end

    payload
  end

  def extract_checkout_url(response)
    parsed = response.parsed_response
    parsed['checkout_url'] || parsed['url'] || parsed['link']
  end

  def send_link_message(checkout_url)
    amount_formatted = format('R$ %.2f', @amount_cents / 100.0)
    content = "💳 *Link de Pagamento*\n\n#{@description}\nValor: #{amount_formatted}\n\n#{checkout_url}"

    @conversation.messages.create!(
      account: @account,
      message_type: :outgoing,
      content: content,
      sender: @user
    )
  end
end
