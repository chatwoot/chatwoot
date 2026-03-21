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
          description: infinitepay_item_description
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
        name: sanitize_customer_name(@conversation.contact.name.presence || phone || 'Cliente'),
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
    @redirect_url ||= whatsapp_conversation? ? whatsapp_redirect_url : fallback_redirect_url
  end

  def whatsapp_redirect_url
    phone = @conversation.inbox.channel&.phone_number.to_s.gsub(/\D/, '')
    phone.present? ? "https://wa.me/#{phone}" : fallback_redirect_url
  end

  def fallback_redirect_url
    "#{base_url}/app/accounts/#{@account.id}/conversations/#{@conversation.display_id}"
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
    template = find_interactive_template
    message_attributes = base_message_attributes(checkout_url)

    if template&.rich_text? && whatsapp_conversation?
      apply_rich_text_attributes!(message_attributes, template, checkout_url)
    elsif template&.cta_url? && whatsapp_conversation?
      apply_cta_attributes!(message_attributes, template, checkout_url)
    end

    @conversation.messages.create!(message_attributes)
  end

  def find_interactive_template
    return if @whatsapp_interactive_template_id.blank?

    @account.whatsapp_interactive_templates.find_by(id: @whatsapp_interactive_template_id)
  end

  def base_message_attributes(checkout_url)
    {
      account: @account,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: plain_text_content(checkout_url),
      sender: @user
    }
  end

  def plain_text_content(checkout_url)
    lines = []
    lines << '┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓'
    lines << '┃ 💰 **LINK DE PAGAMENTO**        ┃'
    lines << '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛'
    lines << ''
    lines << '\> 📄 **Detalhes**'
    lines << "\\> • **Valor:** #{formatted_amount} 💰"
    lines << "\\> • **Ref:** #{@description}" if @description.present?
    lines << ''
    lines << '🔗 **Pague aqui:**'
    lines << checkout_url
    lines << ''
    lines << '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛'
    lines.join("\n")
  end

  def apply_cta_attributes!(attrs, template, checkout_url)
    payload = Whatsapp::InteractiveTemplatePayloadBuilder.new(
      template: template,
      runtime_url: checkout_url,
      runtime_body_text: interactive_body_text(template)
    ).build

    attrs[:content_type] = :integrations
    attrs[:content_attributes] = { interactive: payload }
  rescue StandardError => e
    Rails.logger.warn("[INFINITEPAY-CTA] Falling back to plain text: #{e.class} - #{e.message}")
  end

  def apply_rich_text_attributes!(attrs, template, checkout_url)
    built = Whatsapp::InteractiveTemplatePayloadBuilder.new(
      template: template,
      runtime_body_text: rich_text_body(template, checkout_url)
    ).build

    image_url = built.dig('header', 'image', 'link')
    footer = built.dig('footer', 'text')

    # Body: Ref line right after header, then template body, then link, then footer
    body_parts = [reference_line, "Valor a pagar: #{formatted_amount}"]
    body_parts << template.body_text.to_s.strip if template.body_text.present?
    body_parts << checkout_url
    body_parts << "_#{footer}_" if footer.present?
    attrs[:content] = body_parts.compact.join("\n\n")
    attrs[:content_attributes] = { rich_media: { 'image_url' => image_url }.compact }
  rescue StandardError => e
    Rails.logger.warn("[INFINITEPAY-RICH] Falling back to plain text: #{e.class} - #{e.message}")
  end

  def rich_text_body(template, checkout_url)
    parts = [reference_line, "Valor a pagar: #{formatted_amount}"]
    parts << template.body_text.to_s.strip if template.body_text.present?
    parts << checkout_url
    parts.compact.join("\n\n")
  end

  def whatsapp_conversation?
    @conversation.inbox.channel_type == 'Channel::Whatsapp'
  end

  def formatted_amount
    value = @amount_cents / 100.0
    formatted = format('%.2f', value)
    integer_part, decimal_part = formatted.split('.')
    integer_with_dots = integer_part.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
    "R$ #{integer_with_dots},#{decimal_part}"
  end

  def reference_line
    return if @description.blank?

    "Ref: #{@description}"
  end

  def interactive_body_text(template)
    prefix_lines = ["Valor a pagar: #{formatted_amount}", reference_line].compact
    template_body = template.body_text.to_s.strip
    prefix_text = prefix_lines.join("\n")
    return prefix_text if template_body.blank?

    available_chars = Whatsapp::InteractiveTemplatePayloadBuilder::BODY_MAX - prefix_text.length - 2
    return prefix_text if available_chars <= 0

    [prefix_text, template_body.truncate(available_chars)].join("\n\n")
  end

  def infinitepay_item_description
    parts = [@description.presence]
    parts << "Cliente: #{contact_name}" if contact_name.present?
    parts << "Telefone: #{customer_phone_number}" if customer_phone_number.present?

    parts.compact.join(' | ')
  end

  def contact_name
    @conversation.contact&.name.to_s.strip.presence
  end

  def sanitize_customer_name(name)
    cleaned = name.to_s.strip
    cleaned.length >= 3 ? cleaned : "#{cleaned} Cliente".strip
  end
end
