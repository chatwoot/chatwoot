# frozen_string_literal: true

# lib/integrations/infinitepay/create_link_service.rb
# Creates an InfinitePay checkout link and sends it as a message in the conversation.

class Integrations::Infinitepay::CreateLinkService
  INFINITEPAY_API = 'https://api.infinitepay.io/invoices/public/checkout/links'
  TIMEOUT = 15

  def initialize(account:, conversation:, user:, **options)
    @account = account
    @conversation = conversation
    @user = user
    @amount_cents = options[:amount_cents]
    @description = options[:description]
    @payment_method = options[:payment_method] || 'pix'
    @installments = options[:installments]
    @whatsapp_interactive_template_id = options[:whatsapp_interactive_template_id]
  end

  def perform
    response = HTTParty.post(INFINITEPAY_API, request_options)

    raise "InfinitePay API error: #{response.code} - #{response.body}" unless response.success?

    checkout_url = extract_checkout_url(response)
    payment_link = create_payment_link_record(checkout_url)
    send_link_message(checkout_url)

    payment_link
  end

  private

  def request_options
    {
      headers: { 'Content-Type' => 'application/json' },
      body: build_payload.to_json,
      timeout: TIMEOUT
    }
  end

  def build_payload
    base_payload.merge(customer_payload)
  end

  def base_payload
    {
      handle: infinitepay_handle,
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
  end

  def customer_payload
    return {} if @conversation.contact.blank?

    phone = customer_phone_number
    return {} if customer_identity_blank?(phone)

    {
      customer: {
        name: @conversation.contact.name.presence || phone || 'Cliente',
        email: @conversation.contact.email.presence || 'seuemail@gmail.com',
        phone_number: phone
      }.compact
    }
  end

  def customer_phone_number
    @conversation.contact.phone_number.presence || contact_inbox_identifier(@conversation.contact)
  end

  def customer_identity_blank?(phone)
    phone.blank? && @conversation.contact.name.blank? && @conversation.contact.email.blank?
  end

  def infinitepay_handle
    handle = @account.custom_attributes&.dig('infinitepay_handle')
    raise ArgumentError, 'InfinitePay handle not configured for this account' if handle.blank?

    handle
  end

  def order_nsu
    @order_nsu ||= "chatwit-#{@account.id}-#{@conversation.id}-#{SecureRandom.hex(6)}"
  end

  def webhook_url
    @webhook_url ||= "#{base_url}/webhooks/infinitepay"
  end

  def redirect_url
    @redirect_url ||= "#{base_url}/app/accounts/#{@account.id}/conversations/#{@conversation.display_id}"
  end

  def base_url
    @base_url ||= ENV.fetch('FRONTEND_URL', 'https://chatwit.witdev.com.br')
  end

  def create_payment_link_record(checkout_url)
    PaymentLink.create!(
      account: @account,
      conversation: @conversation,
      user: @user,
      order_nsu: order_nsu,
      amount_cents: @amount_cents,
      description: @description,
      checkout_url: checkout_url,
      status: 'pending'
    )
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
    interactive_payload = build_interactive_payload(checkout_url)
    amount_formatted = format('R$ %.2f', @amount_cents / 100.0)
    content = "💰 *Link de Pagamento*\n\n#{@description}\nValor: #{amount_formatted}\n\n#{checkout_url}"

    message_attributes = {
      account: @account,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      sender: @user
    }

    if interactive_payload.present?
      message_attributes[:content_type] = :integrations
      message_attributes[:content_attributes] = { interactive: interactive_payload }
    end

    @conversation.messages.create!(message_attributes)
  end

  def build_interactive_payload(checkout_url)
    return if @whatsapp_interactive_template_id.blank?
    return unless whatsapp_conversation?

    template = @account.whatsapp_interactive_templates.find_by(id: @whatsapp_interactive_template_id)
    return unless template&.cta_url?

    Whatsapp::InteractiveTemplatePayloadBuilder.new(
      template: template,
      runtime_url: checkout_url
    ).build
  rescue StandardError => e
    Rails.logger.warn("[INFINITEPAY-CTA] Falling back to plain text: #{e.class} - #{e.message}")
    nil
  end

  def whatsapp_conversation?
    @conversation.inbox.channel_type == 'Channel::Whatsapp'
  end
end
