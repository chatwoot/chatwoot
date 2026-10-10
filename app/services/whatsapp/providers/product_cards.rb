module Whatsapp::Providers::ProductCards
  def send_message(phone_number, message)
    return unless bot_turn_current?(message)
    return super unless message.content_attributes.key?('whatsapp_products')

    @message = message
    send_product_cards(phone_number, message)
  end

  private

  def bot_turn_current?(message)
    cutoff = message.content_attributes['bot_reply_to_id']
    return true if cutoff.nil?

    conversation = message.conversation.reload
    statuses = message.content_attributes['bot_handoff'] == true ? %w[pending open] : ['pending']
    current = message.sender_type == 'AgentBot' && cutoff.to_s.match?(/\A[1-9]\d*\z/) && statuses.include?(conversation.status)
    if current
      current = conversation.messages.where(private: false, message_type: :outgoing).where('id > ?', cutoff)
                            .where("sender_type = 'User' OR content_attributes ->> 'external_echo' = 'true'").none?
    end
    return true if current

    message.update!(status: :failed, external_error: 'Bot response cancelled: conversation taken over or turn invalid')
    false
  end

  def send_product_cards(phone_number, message)
    interactive = Whatsapp::ProductCardsPayload.build(message.content_attributes['whatsapp_products'])
    response = HTTParty.post(
      "#{phone_id_path('v23.0')}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp', recipient_type: 'individual', **recipient_params(phone_number),
        context: whatsapp_reply_context(message), type: 'interactive', interactive: interactive
      }.to_json
    )
    process_response(response, message)
  rescue ArgumentError
    message.update!(status: :failed, external_error: 'Invalid WhatsApp product cards')
    nil
  end
end
