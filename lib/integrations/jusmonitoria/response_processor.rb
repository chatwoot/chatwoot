# frozen_string_literal: true

# lib/integrations/jusmonitoria/response_processor.rb
# Processes sync responses from JusMonitorIA and sends them back to the lead.
# Reuses SocialWise's WhatsApp and Instagram response processors for rich messages.

class Integrations::Jusmonitoria::ResponseProcessor
  pattr_initialize [:message!, :response!]

  def perform
    Rails.logger.info "[JUSMONITORIA-RESPONSE] === Processing response ==="

    process_actions
    process_responses

    Rails.logger.info "[JUSMONITORIA-RESPONSE] === Response processing completed ==="
  rescue StandardError => e
    Rails.logger.error "[JUSMONITORIA-RESPONSE] Error: #{e.class}: #{e.message}"
    Rails.logger.error "[JUSMONITORIA-RESPONSE] Backtrace: #{e.backtrace.first(5).join("\n")}"
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
  end

  private

  def conversation
    @conversation ||= message.conversation
  end

  def inbox
    @inbox ||= conversation.inbox
  end

  def channel_type
    @channel_type ||= inbox.channel_type
  end

  # --- Actions ---

  def process_actions
    actions = response['actions']
    return if actions.blank?

    actions = [actions] if actions.is_a?(String)

    actions.each do |action|
      case action
      when 'handoff'
        handle_handoff
      when 'resolve'
        handle_resolve
      end
    end
  end

  def handle_handoff
    Rails.logger.info "[JUSMONITORIA-RESPONSE] Handoff requested for conversation #{conversation.id}"
    conversation.update!(assignee_agent_bot_id: nil) if conversation.respond_to?(:assignee_agent_bot_id)
    conversation.open! if conversation.respond_to?(:open!)
  end

  def handle_resolve
    Rails.logger.info "[JUSMONITORIA-RESPONSE] Resolve requested for conversation #{conversation.id}"
    conversation.resolved! if conversation.respond_to?(:resolved!)
  end

  # --- Responses ---

  def process_responses
    responses = response['responses']
    return if responses.blank?

    responses.each do |resp|
      process_single_response(resp)
    end
  end

  def process_single_response(resp)
    case resp['type']
    when 'text'
      send_text_response(resp['content'])
    when 'interactive'
      send_interactive_response(resp)
    when 'template'
      send_template_response(resp)
    else
      # Fallback to text if content is present
      send_text_response(resp['content']) if resp['content'].present?
    end
  end

  def send_text_response(content)
    return if content.blank?

    Rails.logger.info "[JUSMONITORIA-RESPONSE] Sending text response to conversation #{conversation.id}"
    create_outgoing_message(content)
  end

  def send_interactive_response(resp)
    Rails.logger.info "[JUSMONITORIA-RESPONSE] Sending interactive response via #{channel_type}"

    case channel_type
    when 'Channel::Whatsapp'
      process_whatsapp_interactive(resp)
    when 'Channel::Instagram', 'Channel::FacebookPage'
      process_instagram_interactive(resp)
    else
      # Fallback to text for unsupported channels
      send_text_response(resp['content'] || resp.dig('payload', 'body', 'text') || 'Interactive message')
    end
  end

  def send_template_response(resp)
    Rails.logger.info "[JUSMONITORIA-RESPONSE] Sending template response via #{channel_type}"

    case channel_type
    when 'Channel::Whatsapp'
      process_whatsapp_template(resp)
    else
      send_text_response(resp['content'] || 'Template message')
    end
  end

  # --- WhatsApp ---

  def process_whatsapp_interactive(resp)
    whatsapp_payload = resp['whatsapp'] || resp['payload']
    if whatsapp_payload.present?
      Integrations::SocialwiseFlow::WhatsappResponseProcessor.new(
        message: message,
        response: { 'whatsapp' => whatsapp_payload }
      ).perform
    else
      send_text_response(resp['content'] || 'Interactive message')
    end
  rescue StandardError => e
    Rails.logger.error "[JUSMONITORIA-RESPONSE] WhatsApp interactive error: #{e.message}"
    send_text_response(resp['content'] || 'Interactive message')
  end

  def process_whatsapp_template(resp)
    template_payload = resp['whatsapp'] || resp['payload']
    if template_payload.present?
      Integrations::SocialwiseFlow::WhatsappResponseProcessor.new(
        message: message,
        response: { 'whatsapp' => template_payload }
      ).perform
    else
      send_text_response(resp['content'] || 'Template message')
    end
  rescue StandardError => e
    Rails.logger.error "[JUSMONITORIA-RESPONSE] WhatsApp template error: #{e.message}"
    send_text_response(resp['content'] || 'Template message')
  end

  # --- Instagram/Facebook ---

  def process_instagram_interactive(resp)
    instagram_payload = resp['instagram'] || resp['payload']
    if instagram_payload.present?
      Integrations::Socialwise::InstagramResponseProcessor.process(instagram_payload, message)
    else
      send_text_response(resp['content'] || 'Interactive message')
    end
  rescue StandardError => e
    Rails.logger.error "[JUSMONITORIA-RESPONSE] Instagram interactive error: #{e.message}"
    send_text_response(resp['content'] || 'Interactive message')
  end

  # --- Message Creation ---

  def create_outgoing_message(content)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      content_attributes: { 'source' => 'jusmonitoria' }
    )
  end
end
