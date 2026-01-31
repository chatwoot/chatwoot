# frozen_string_literal: true

class Aloo::ResponseService
  def initialize(conversation, message)
    @conversation = conversation
    @message = message
    @assistant = conversation.aloo_assistant
  end

  def call
    return unless processable?

    with_context do
      with_typing_indicator do
        result = generate_response
        send_response(result) if result.success? && result.content.present?
      end
    end
  end

  private

  def processable?
    @assistant&.active? && !human_assigned? && @message.incoming?
  end

  def human_assigned?
    @conversation.assignee.present? && !@conversation.assignee.try(:is_ai?)
  end

  def with_context
    Aloo::Current.account = @conversation.account
    Aloo::Current.assistant = @assistant
    Aloo::Current.conversation = @conversation
    Aloo::Current.request_id = SecureRandom.uuid
    yield
  ensure
    Aloo::Current.reset
  end

  def with_typing_indicator
    dispatch_typing(Events::Types::CONVERSATION_TYPING_ON)
    send_whatsapp_typing_indicator
    yield
  ensure
    dispatch_typing(Events::Types::CONVERSATION_TYPING_OFF)
  end

  def dispatch_typing(event)
    Rails.configuration.dispatcher.dispatch(
      event, Time.zone.now,
      conversation: @conversation, user: @assistant, is_private: false
    )
  end

  def send_whatsapp_typing_indicator
    channel = whatsapp_cloud_channel
    return unless channel

    phone_number = @conversation.contact_inbox.source_id
    return if phone_number.blank?

    Rails.logger.info "[ALOO] Sending WhatsApp typing indicator to #{phone_number}"
    service = Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel)
    service.send_typing_indicator(phone_number, message_id: @message.source_id)
  rescue StandardError => e
    Rails.logger.error "[ALOO] Failed to send WhatsApp typing indicator: #{e.message}"
  end

  def whatsapp_cloud_channel
    inbox = @conversation.inbox
    return unless inbox.channel_type == 'Channel::Whatsapp'

    channel = inbox.channel
    return unless channel.respond_to?(:provider_name) && channel.provider_name == 'whatsapp_cloud'

    channel
  end

  def generate_response
    message_content = @message.content_for_llm
    return OpenStruct.new(success?: false) if message_content.blank?

    ConversationAgent.call(message: message_content)
  end

  def send_response(result)
    return if handoff_triggered?(result)

    message = create_message(result)
    return unless message&.persisted?

    dispatch_reply(message)
    update_conversation_status
    trigger_voice_reply(message)
  end

  def handoff_triggered?(result)
    result.respond_to?(:tool_calls) && result.tool_calls&.any? { |tc| tc['name'] == 'handoff' }
  end

  def create_message(result)
    Messages::MessageBuilder.new(
      @assistant,
      @conversation,
      {
        content: result.content,
        message_type: :outgoing,
        private: false,
        content_attributes: {
          'aloo_generated' => true,
          'aloo_assistant_id' => @assistant.id,
          'input_tokens' => result.input_tokens,
          'output_tokens' => result.output_tokens,
          'tool_calls' => result.tool_calls&.pluck('name')
        }
      }
    ).perform
  end

  def dispatch_reply(message)
    ::SendReplyJob.perform_later(message.id)
  end

  def update_conversation_status
    return unless @conversation.pending?

    @conversation.update!(status: :open)
  end

  def trigger_voice_reply(message)
    return unless @assistant.voice_reply_enabled?
    return unless incoming_message_has_audio?

    Aloo::VoiceReplyJob.perform_later(message.id)
  end

  def incoming_message_has_audio?
    @message.attachments.exists?(file_type: 'audio')
  end
end
