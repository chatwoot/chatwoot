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
    if order_nsu.blank?
      Rails.logger.warn '[INFINITEPAY] Webhook ignored because order_nsu is missing'
      return
    end

    Rails.logger.info "[INFINITEPAY] Webhook received for order_nsu=#{order_nsu}"

    payment_link = PaymentLink.find_by(order_nsu: order_nsu)

    # AUTO-CREATE: link gerado pelo Socialwise Flow (mesmo formato order_nsu)
    if payment_link.nil?
      payment_link = auto_create_from_webhook(order_nsu)
      if payment_link.nil?
        Rails.logger.error "[INFINITEPAY] Webhook ignored because PaymentLink was not found or auto-created for order_nsu=#{order_nsu}"
        return
      end
    end

    already_paid = payment_link.paid?

    Rails.logger.info(
      "[INFINITEPAY] Processing payment_link=#{payment_link.id} conversation_id=#{payment_link.conversation_id} already_paid=#{already_paid}"
    )

    payment_link.mark_as_paid!(@payload) unless already_paid

    notification_payload = payment_notification_payload(payment_link)
    @notification_content = notification_payload[:content]

    send_confirmation_message(payment_link, notification_payload)

    if already_paid
      Rails.logger.warn(
        "[INFINITEPAY] PaymentLink #{payment_link.id} was already paid. Confirmation message was checked, but push/forward were skipped to avoid duplicates"
      )
      return payment_link
    end

    send_payment_push(payment_link, notification_payload)
    forward_to_integrations(payment_link)

    payment_link
  end

  private

  # Parseia "chatwit-{accountId}-{conversationId}-{hex}" e cria PaymentLink on-the-fly
  def auto_create_from_webhook(order_nsu)
    parts = order_nsu.split('-')
    return nil unless parts.length >= 4 && parts[0] == 'chatwit'

    account_id = parts[1].to_i
    conversation_id = parts[2].to_i

    account = Account.find_by(id: account_id)
    return nil if account.nil?

    conversation = account.conversations.find_by(id: conversation_id)
    return nil if conversation.nil?

    amount_cents = (@payload['amount'] || @payload['paid_amount'] || 0).to_i
    description = Array(@payload['items']).first&.dig('description') || 'Pagamento via Flow'

    PaymentLink.create!(
      account: account,
      conversation: conversation,
      user: nil,
      order_nsu: order_nsu,
      amount_cents: [amount_cents, 1].max,
      description: description,
      checkout_url: '',
      status: 'pending'
    )
  rescue StandardError => e
    Rails.logger.error "[INFINITEPAY] Auto-create PaymentLink failed: #{e.message}"
    nil
  end

  def send_confirmation_message(payment_link, notification_payload)
    conversation = payment_link.conversation
    account = payment_link.account

    if confirmation_message_sent?(payment_link)
      Rails.logger.info "[INFINITEPAY] Confirmation message already exists for payment_link=#{payment_link.id}"
      return
    end

    conversation.messages.create!(
      account: account,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: notification_payload[:content],
      additional_attributes: {
        payment_link_id: payment_link.id,
        infinitepay_event: 'payment_confirmed'
      }
    )

    Rails.logger.info "[INFINITEPAY] Confirmation message created for payment_link=#{payment_link.id}"
  end

  def send_payment_push(payment_link, notification_payload)
    Integrations::Infinitepay::PushNotificationService.new(
      payment_link: payment_link,
      notification_payload: notification_payload.slice(:title, :body, :tag, :url)
    ).perform
  end

  def forward_to_integrations(payment_link)
    account = payment_link.account
    event_payload = build_event_payload(payment_link)

    forward_to_jusmonitoria(event_payload, account)
    forward_to_socialwise(event_payload, account)
  end

  def build_event_payload(payment_link)
    conversation = payment_link.conversation
    contact = conversation.contact
    {
      payment_link_id: payment_link.id,
      order_nsu: payment_link.order_nsu,
      amount_cents: payment_link.amount_cents,
      paid_amount_cents: payment_link.paid_amount_cents,
      capture_method: payment_link.capture_method,
      receipt_url: payment_link.receipt_url,
      conversation_id: payment_link.conversation_id,
      contact: payment_contact_payload(contact),
      conversation: payment_conversation_payload(conversation),
      inbox: payment_inbox_payload(conversation.inbox)
    }
  end

  def payment_contact_payload(contact)
    return { id: nil, name: nil, phone_number: nil } if contact.blank?

    contact.webhook_data
  end

  def payment_conversation_payload(conversation)
    return {} if conversation.blank?

    conversation.webhook_data.merge(
      labels: conversation.cached_label_list_array,
      contact: conversation.contact&.webhook_data,
      inbox: payment_inbox_payload(conversation.inbox)
    )
  end

  def payment_inbox_payload(inbox)
    return {} if inbox.blank?

    { id: inbox.id, name: inbox.name, channel_type: inbox.channel_type }
  end

  def forward_to_jusmonitoria(event_payload, account)
    response = Integrations::Jusmonitoria::WebhookForwarderService.forward_event(
      event_type: 'payment.confirmed',
      payload: event_payload,
      account: account
    )

    if response&.success?
      Rails.logger.info(
        "[INFINITEPAY] Forwarded payment.confirmed to JusMonitorIA account=#{account.id} order_nsu=#{event_payload[:order_nsu]} status=#{response.code}"
      )
    else
      Rails.logger.error(
        "[INFINITEPAY] JusMonitorIA forward failed account=#{account.id} order_nsu=#{event_payload[:order_nsu]} status=#{response&.code} body=#{response&.body.to_s.truncate(500)}"
      )
    end
  rescue StandardError => e
    Rails.logger.error "[INFINITEPAY] Failed to forward to JusMonitorIA: #{e.message}"
  end

  def forward_to_socialwise(event_payload, account)
    endpoint = ENV.fetch('SOCIALWISE_WEBHOOK_URL', nil)
    if endpoint.blank?
      Rails.logger.warn "[INFINITEPAY] SOCIALWISE_WEBHOOK_URL not configured. Skipping payment.confirmed forward for order_nsu=#{event_payload[:order_nsu]}"
      return
    end

    body = {
      event: 'message_created',
      message_type: 'outgoing',
      content_type: 'text',
      content: @notification_content,
      additional_attributes: {
        payment_link_id: event_payload[:payment_link_id],
        infinitepay_event: 'payment_confirmed'
      },
      conversation: {
        id: event_payload[:conversation_id],
        meta: {
          sender: {
            phone_number: event_payload[:contact][:phone_number],
            name: event_payload[:contact][:name]
          }
        }
      },
      account: { id: account.id },
      payment_data: event_payload
    }

    headers = { 'Content-Type' => 'application/json' }
    secret = ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)
    headers['X-Chatwit-Secret'] = secret if secret.present?

    response = HTTParty.post(
      "#{endpoint}/api/integrations/payment",
      headers: headers,
      body: body.to_json,
      timeout: 15
    )

    if response.success?
      Rails.logger.info(
        "[INFINITEPAY] Forwarded payment.confirmed to SocialWise /api/integrations/payment account=#{account.id} order_nsu=#{event_payload[:order_nsu]} status=#{response.code}"
      )
    else
      Rails.logger.error(
        "[INFINITEPAY] SocialWise payment forward failed account=#{account.id} order_nsu=#{event_payload[:order_nsu]} status=#{response.code} body=#{response.body.to_s.truncate(500)}"
      )
    end
  rescue StandardError => e
    Rails.logger.error "[INFINITEPAY] Failed to forward to SocialWise: #{e.message}"
  end

  def payment_notification_payload(payment_link)
    conversation = payment_link.conversation
    contact_name = conversation.contact&.name || 'Cliente'
    installments = @payload['installments'].to_i
    capture_detail = if @payload['capture_method'] == 'pix'
                       'PIX 🏦'
                     elsif installments > 1
                       "Cartão #{installments}x 💳"
                     else
                       'Cartão de Crédito 💳'
                     end
    amount_formatted = format_brl((@payload['amount'] || payment_link.amount_cents) / 100.0)
    transaction_code = @payload['transaction_nsu'].presence || payment_link.transaction_nsu.presence || payment_link.order_nsu
    receipt_url = @payload['receipt_url'].presence || payment_link.receipt_url
    title = 'Pagamento Confirmado!'
    body = "Olá, #{contact_name}! Pagamento de #{amount_formatted} recebido com sucesso."

    content = <<~MSG.strip
      ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
      ┃ 🎉 **PAGAMENTO CONFIRMADO!**   ┃
      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

      Olá, **#{contact_name}**! 👋
       Seu pagamento foi recebido com sucesso. ✅

      \\> 📄 **Detalhes da transação**
      \\> • **Descrição:** #{payment_link.description}
      \\> • **Valor:** #{amount_formatted} 💰
      \\> • **Pagamento:** #{capture_detail}
      \\> • **Código:** #{transaction_code}

      🧾 **Comprovante**
      #{receipt_url}

       🙏 Obrigado pela confiança!
       Qualquer dúvida, estamos à disposição.

      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
    MSG

    {
      title: title,
      body: body,
      content: content,
      tag: "infinitepay_payment_confirmed_#{payment_link.id}",
      url: conversation_url(conversation)
    }
  end

  def format_brl(value)
    formatted = format('%.2f', value)
    integer_part, decimal_part = formatted.split('.')
    integer_with_dots = integer_part.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
    "R$ #{integer_with_dots},#{decimal_part}"
  end

  def conversation_url(conversation)
    base_url = ENV.fetch('FRONTEND_URL', 'https://chatwit.witdev.com.br').chomp('/')
    "#{base_url}/app/accounts/#{conversation.account_id}/conversations/#{conversation.display_id}"
  end

  def confirmation_message_sent?(payment_link)
    payment_link.conversation.messages
                .outgoing
                .where("additional_attributes ->> 'payment_link_id' = ?", payment_link.id.to_s)
                .where("additional_attributes ->> 'infinitepay_event' = ?", 'payment_confirmed')
                .exists?
  end
end
