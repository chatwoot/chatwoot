# Service for sending rendered template messages to conversations
# Used by bots and external systems to send rich content via templates
class Templates::BotMessagingService
  class SendError < StandardError; end

  def initialize(conversation:, template:, parameters:, sender:)
    @conversation = conversation
    @template = template
    @parameters = parameters
    @sender = sender
  end

  def send_template_message
    # Render the template for the conversation's channel
    channel_type = determine_channel_type

    renderer = Templates::BotRendererService.new(
      template_id: @template.id,
      parameters: @parameters,
      channel_type: channel_type
    )

    rendered = renderer.render_for_bot

    # Create the message
    message = create_message(rendered)

    # Trigger conversation events
    trigger_events(message)

    message
  rescue StandardError => e
    Rails.logger.error "[Templates::BotMessagingService] Failed to send message: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise SendError, "Failed to send template message: #{e.message}"
  end

  private

  def determine_channel_type
    # Convert inbox channel to standardized template channel type
    case @conversation.inbox.channel_type
    when 'Channel::AppleMessagesForBusiness'
      'apple_messages_for_business'
    when 'Channel::Whatsapp'
      'whatsapp'
    when 'Channel::WebWidget', 'Channel::Api'
      'web_widget'
    else
      # Fallback to a generic type
      @conversation.inbox.channel_type.demodulize.underscore
    end
  end

  def create_message(rendered)
    message_params = {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: rendered[:content],
      sender_type: @sender.class.name,
      sender_id: @sender.id
    }

    # Add content_type and content_attributes if present
    message_params[:content_type] = rendered[:contentType] if rendered[:contentType].present?
    message_params[:content_attributes] = rendered[:contentAttributes] if rendered[:contentAttributes].present?

    # Add additional metadata
    message_params[:additional_attributes] = {
      template_id: @template.id,
      template_name: @template.name,
      rendered_at: Time.current.iso8601
    }

    @conversation.messages.create!(message_params)
  end

  def trigger_events(message)
    # Trigger Rails events for message creation
    # This will be picked up by webhooks and other listeners
    Rails.configuration.dispatcher.dispatch(
      Events::BASE_EVENTS[:message_created],
      Time.zone.now,
      message: message,
      conversation: @conversation
    )
  rescue StandardError => e
    Rails.logger.error "[Templates::BotMessagingService] Failed to trigger events: #{e.message}"
    # Don't fail the message creation if event dispatch fails
  end
end
