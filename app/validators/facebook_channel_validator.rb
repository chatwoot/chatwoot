# frozen_string_literal: true

# Validator for Facebook Messenger (Channel::FacebookPage)
class FacebookChannelValidator
  include ActiveModel::Validations

  attr_reader :message, :conversation, :inbox, :channel, :errors

  def initialize(message)
    @message = message
    @conversation = message.conversation
    @inbox = conversation.inbox
    @channel = inbox.channel
    @errors = []
  end

  def valid_for_rich_messages?
    Rails.logger.info '[SOCIALWISE-FACEBOOK-VALIDATOR] === STARTING FACEBOOK CHANNEL VALIDATION ==='
    Rails.logger.info "[SOCIALWISE-FACEBOOK-VALIDATOR] Message ID: #{message.id}, Conversation ID: #{conversation.id}"
    Rails.logger.info "[SOCIALWISE-FACEBOOK-VALIDATOR] Account ID: #{conversation.account_id}, Inbox ID: #{inbox.id}"
    Rails.logger.info "[SOCIALWISE-FACEBOOK-VALIDATOR] Channel type: #{inbox.channel_type}, Channel ID: #{channel&.id}"

    started = Time.current
    @errors = []

    validate_channel_type &&
      validate_channel_presence &&
      validate_credentials &&
      validate_contact_mapping
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-FACEBOOK-VALIDATOR] Validation exception: #{e.class}: #{e.message}"
    @errors << "Validation failed due to system error: #{e.message}"
    false
  ensure
    duration = ((Time.current - started) * 1000).round(2)
    if @errors.empty?
      Rails.logger.info '[SOCIALWISE-FACEBOOK-VALIDATOR] === FACEBOOK CHANNEL VALIDATION PASSED ==='
      Rails.logger.info "[SOCIALWISE-FACEBOOK-VALIDATOR] Validation time: #{duration}ms"
    else
      Rails.logger.error '[SOCIALWISE-FACEBOOK-VALIDATOR] === FACEBOOK CHANNEL VALIDATION FAILED ==='
      Rails.logger.error "[SOCIALWISE-FACEBOOK-VALIDATOR] Validation errors: #{@errors.join(', ')}"
      Rails.logger.error "[SOCIALWISE-FACEBOOK-VALIDATOR] Validation time: #{duration}ms"
    end
  end

  def error_messages
    @errors.join('; ')
  end

  def validation_status
    {
      valid: @errors.empty?,
      channel_type: inbox.channel_type,
      channel_present: channel.present?,
      page_id_present: channel&.page_id.present?,
      page_access_token_present: channel&.page_access_token.present?,
      contact_source_id_present: begin
        conversation.contact&.get_source_id(inbox.id).present?
      rescue StandardError
        false
      end,
      errors: @errors
    }
  end

  private

  def validate_channel_type
    return true if inbox.channel_type == 'Channel::FacebookPage' && channel.is_a?(Channel::FacebookPage)

    @errors << "Rich messages only supported for FacebookPage channels, got: #{inbox.channel_type}"
    false
  end

  def validate_channel_presence
    unless channel.present?
      @errors << "Facebook channel configuration not found for inbox #{inbox.id}"
      return false
    end
    true
  end

  def validate_credentials
    if channel.page_id.blank?
      @errors << 'Facebook Page ID missing'
      return false
    end
    if channel.page_access_token.blank?
      @errors << 'Facebook Page Access Token missing'
      return false
    end
    true
  end

  def validate_contact_mapping
    source_id = conversation.contact&.get_source_id(inbox.id)
    if source_id.blank?
      @errors << 'Contact source_id missing for this inbox'
      return false
    end
    true
  end
end
