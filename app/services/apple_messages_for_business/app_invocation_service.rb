class AppleMessagesForBusiness::AppInvocationService
  include ApplicationHelper

  def initialize(conversation:, message:)
    @conversation = conversation
    @message = message
    @channel = @conversation.inbox.channel
  end

  def process_app_invocation
    validate_channel!
    validate_message_content!

    app_config = extract_app_config
    destination_id = @conversation.contact_inbox.source_id

    extension_service = AppleMessagesForBusiness::CustomExtensionService.new(
      channel: @channel,
      destination_id: destination_id,
      app_config: app_config
    )

    result = extension_service.create_app_invocation_message

    if result[:success]
      update_message_with_result(result)
      log_successful_invocation(result[:message_id])
    else
      handle_invocation_error(result[:error])
    end

    result
  rescue StandardError => e
    Rails.logger.error "App invocation service failed: #{e.message}"
    { success: false, error: e.message }
  end

  def self.handle_incoming_app_response(channel:, payload:)
    # Handle responses from custom iMessage apps
    message_data = payload.dig('message')
    return unless message_data

    conversation = find_conversation_by_source_id(channel, payload['sourceId'])
    return unless conversation

    # Extract app response data
    app_response = extract_app_response_data(message_data)

    # Create response message in Chatwoot
    create_app_response_message(conversation, app_response)

    # Trigger any configured webhooks or automations
    trigger_app_response_hooks(conversation, app_response)
  end

  private

  def validate_channel!
    unless @channel.is_a?(Channel::AppleMessagesForBusiness)
      raise ArgumentError, 'Channel must be Apple Messages for Business'
    end
  end

  def validate_message_content!
    unless @message.content_type == 'apple_custom_app'
      raise ArgumentError, 'Message must have apple_custom_app content type'
    end

    unless @message.content_attributes.present?
      raise ArgumentError, 'Message must have content attributes for app configuration'
    end
  end

  def extract_app_config
    attributes = @message.content_attributes

    config = {
      'app_id' => attributes['app_id'],
      'bid' => attributes['bid'],
      'version' => attributes['version'] || '1.0',
      'use_live_layout' => attributes['use_live_layout'] != false,
      'url' => attributes['url'],
      'app_data' => attributes['app_data'] || {},
      'images' => attributes['images'] || [],
      'received_message' => attributes['received_message'],
      'reply_message' => attributes['reply_message']
    }

    # Add any additional parameters from the message content
    if attributes['parameters'].present?
      config['app_data'].merge!(attributes['parameters'])
    end

    config
  end

  def update_message_with_result(result)
    @message.update!(
      external_source_id: result[:message_id],
      status: 'sent'
    )

    # Store the full payload for debugging and tracking
    @message.content_attributes['sent_payload'] = result[:payload]
    @message.content_attributes['sent_at'] = Time.current.iso8601
    @message.save!
  end

  def log_successful_invocation(message_id)
    Rails.logger.info "Custom app invocation successful - Message ID: #{message_id}, " \
                      "Conversation: #{@conversation.id}, Channel: #{@channel.id}"
  end

  def handle_invocation_error(error)
    Rails.logger.error "Custom app invocation failed - Error: #{error}, " \
                       "Conversation: #{@conversation.id}, Message: #{@message.id}"

    @message.update!(status: 'failed')

    # Store error information for debugging
    @message.content_attributes['error'] = error
    @message.content_attributes['failed_at'] = Time.current.iso8601
    @message.save!
  end

  def self.find_conversation_by_source_id(channel, source_id)
    contact_inbox = ContactInbox.find_by(
      inbox: channel.inbox,
      source_id: source_id
    )

    contact_inbox&.conversations&.last
  end

  def self.extract_app_response_data(message_data)
    {
      app_id: message_data.dig('interactiveData', 'bid'),
      response_data: message_data.dig('interactiveData', 'data'),
      message_content: message_data['body'],
      received_at: Time.current.iso8601,
      apple_message_id: message_data['id']
    }
  end

  def self.create_app_response_message(conversation, app_response)
    message = conversation.messages.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      message_type: 'incoming',
      content: format_app_response_content(app_response),
      content_type: 'apple_custom_app_response',
      content_attributes: {
        app_id: app_response[:app_id],
        response_data: app_response[:response_data],
        apple_message_id: app_response[:apple_message_id],
        received_at: app_response[:received_at]
      },
      external_source_id: app_response[:apple_message_id],
      sender: conversation.contact
    )

    # Trigger conversation updated event
    Rails.application.event_store.publish(
      Events::MessageCreated.new(data: { message: message })
    )

    message
  end

  def self.format_app_response_content(app_response)
    content = app_response[:message_content]

    # If no text content, create a summary of the app response
    if content.blank?
      app_name = app_response[:app_id]&.split(':')&.last || 'Custom App'
      content = "Response from #{app_name}"
    end

    content
  end

  def self.trigger_app_response_hooks(conversation, app_response)
    # Trigger any configured webhooks for app responses
    if conversation.account.feature_enabled?(:webhooks)
      WebhookJob.perform_later(
        conversation.account,
        :app_response_received,
        {
          conversation: conversation,
          app_response: app_response
        }
      )
    end

    # Trigger automation rules if configured
    AutomationRuleJob.perform_later(
      conversation,
      :app_response_received,
      app_response
    )
  end
end