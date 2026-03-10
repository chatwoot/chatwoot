# frozen_string_literal: true

# lib/integrations/infinitepay/webhook_processor_service.rb
# Processes incoming InfinitePay webhook payloads (payment confirmations).
# Updates the PaymentLink record and forwards the event to SocialWise + JusMonitorIA.

class Integrations::Infinitepay::WebhookProcessorService
  def initialize(payload)
    @payload = payload
  end

  def perform
    order_nsu = @payload['order_nsu']
    return if order_nsu.blank?

    payment_link = PaymentLink.find_by(order_nsu: order_nsu)
    return if payment_link.nil?
    return if payment_link.paid?

    payment_link.mark_as_paid!(@payload)

    send_confirmation_message(payment_link)
    forward_to_integrations(payment_link)

    payment_link
  end

  private

  def send_confirmation_message(payment_link)
    conversation = payment_link.conversation
    account = payment_link.account
    capture = @payload['capture_method'] == 'pix' ? 'PIX' : 'Cartão de Crédito'
    amount_formatted = format('R$ %.2f', (@payload['paid_amount'] || payment_link.amount_cents) / 100.0)

    content = "✅ *Pagamento Confirmado*\n\nValor: #{amount_formatted}\nMétodo: #{capture}\nComprovante: #{@payload['receipt_url']}"

    conversation.messages.create!(
      account: account,
      message_type: :outgoing,
      content: content,
      content_type: :text
    )
  end

  def forward_to_integrations(payment_link)
    account = payment_link.account
    event_payload = build_event_payload(payment_link)

    forward_to_jusmonitoria(event_payload, account)
    forward_to_socialwise(event_payload, account)
  end

  def build_event_payload(payment_link)
    contact = payment_link.conversation.contact
    {
      payment_link_id: payment_link.id,
      order_nsu: payment_link.order_nsu,
      amount_cents: payment_link.amount_cents,
      paid_amount_cents: payment_link.paid_amount_cents,
      capture_method: payment_link.capture_method,
      receipt_url: payment_link.receipt_url,
      conversation_id: payment_link.conversation_id,
      contact: {
        id: contact&.id,
        name: contact&.name,
        phone_number: contact&.phone_number
      }
    }
  end

  def forward_to_jusmonitoria(event_payload, account)
    Integrations::Jusmonitoria::WebhookForwarderService.forward_event(
      event_type: 'payment.confirmed',
      payload: event_payload,
      account: account
    )
  rescue StandardError => e
    Rails.logger.error "[INFINITEPAY] Failed to forward to JusMonitorIA: #{e.message}"
  end

  def forward_to_socialwise(event_payload, account)
    endpoint = ENV.fetch('SOCIALWISE_WEBHOOK_URL', nil)
    return if endpoint.blank?

    body = {
      event_type: 'payment.confirmed',
      data: event_payload,
      metadata: {
        account_id: account.id,
        chatwit_base_url: ENV.fetch('FRONTEND_URL', 'https://chatwit.witdev.com.br'),
        timestamp: Time.current.iso8601
      }
    }

    headers = { 'Content-Type' => 'application/json' }
    secret = ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)
    headers['X-Chatwit-Secret'] = secret if secret.present?

    HTTParty.post(
      "#{endpoint}/v1/integrations/chatwit",
      headers: headers,
      body: body.to_json,
      timeout: 15
    )
  rescue StandardError => e
    Rails.logger.error "[INFINITEPAY] Failed to forward to SocialWise: #{e.message}"
  end
end
