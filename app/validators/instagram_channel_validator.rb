# frozen_string_literal: true

# Validator for Instagram channel configuration and compatibility checks
# Used to ensure rich message processing only occurs for properly configured Instagram inboxes
class InstagramChannelValidator
  include ActiveModel::Validations

  attr_reader :message, :conversation, :inbox, :channel, :errors

  def initialize(message)
    @message = message
    @conversation = message.conversation
    @inbox = conversation.inbox
    @channel = inbox.channel
    @errors = []
  end

  # Main validation method that performs all Instagram channel checks
  # @return [Boolean] true if all validations pass, false otherwise
  def valid_for_rich_messages?
    Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] === STARTING INSTAGRAM CHANNEL VALIDATION ==='
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Message ID: #{message.id}, Conversation ID: #{conversation.id}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Account ID: #{conversation.account_id}, Inbox ID: #{inbox.id}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Channel type: #{inbox.channel_type}, Channel ID: #{channel&.id}"

    validation_start_time = Time.current

    # Clear any previous errors
    @errors = []

    # Perform all validation checks
    validate_instagram_channel_type &&
      validate_channel_configuration &&
      validate_access_token_availability &&
      validate_instagram_id_presence &&
      validate_channel_not_expired
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] Validation failed with exception: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] Backtrace: #{e.backtrace.join('\n')}"
    add_error("Validation failed due to system error: #{e.message}")
    false
  ensure
    validation_end_time = Time.current
    validation_duration = ((validation_end_time - validation_start_time) * 1000).round(2)

    if @errors.empty?
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] === INSTAGRAM CHANNEL VALIDATION PASSED ==='
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] All validation checks passed successfully'
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Validation time: #{validation_duration}ms"
    else
      Rails.logger.error '[SOCIALWISE-INSTAGRAM-VALIDATOR] === INSTAGRAM CHANNEL VALIDATION FAILED ==='
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] Validation errors: #{@errors.join(', ')}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] Validation time: #{validation_duration}ms"
    end
  end

  # Get all validation errors as a formatted string
  # @return [String] formatted error messages
  def error_messages
    @errors.join('; ')
  end

  # Check if the channel is compatible with rich messages (Instagram only)
  # @return [Boolean] true if compatible, false otherwise
  def compatible_channel?
    # Instagram uses Channel::FacebookPage, not Channel::Instagram
    inbox.channel_type == 'Channel::FacebookPage' && channel.is_a?(Channel::Instagram)
  end

  # Get detailed validation status for debugging
  # @return [Hash] detailed validation status
  def validation_status
    {
      valid: @errors.empty?,
      channel_type: inbox.channel_type,
      is_instagram: compatible_channel?,
      channel_present: channel.present?,
      access_token_present: channel&.access_token.present?,
      instagram_id_present: channel&.instagram_id.present?,
      channel_expired: channel_expired?,
      errors: @errors
    }
  end

  private

  # Validate that the channel is Instagram
  # @return [Boolean] true if Instagram channel, false otherwise
  def validate_instagram_channel_type
    Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] Validating channel type'
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Inbox channel_type: #{inbox.channel_type}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Channel class: #{channel&.class}"

    # Instagram can use Channel::FacebookPage or Channel::Instagram as channel_type
    valid_instagram_channel_types = %w[Channel::FacebookPage Channel::Instagram]
    unless valid_instagram_channel_types.include?(inbox.channel_type)
      error_msg = "Rich messages only supported for Instagram channels, got: #{inbox.channel_type}"
      Rails.logger.warn "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
      add_error(error_msg)
      return false
    end

    unless channel.is_a?(Channel::Instagram)
      error_msg = "Rich messages only supported for Instagram channels, got channel class: #{channel&.class}"
      Rails.logger.warn "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
      add_error(error_msg)
      return false
    end

    Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Channel type validation passed: #{inbox.channel_type} with #{channel.class}"
    true
  end

  # Validate that the channel configuration exists and is properly set up
  # @return [Boolean] true if channel is properly configured, false otherwise
  def validate_channel_configuration
    Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] Validating channel configuration'

    unless channel.present?
      error_msg = "Instagram channel configuration not found for inbox #{inbox.id}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
      add_error(error_msg)
      return false
    end

    unless channel.is_a?(Channel::Instagram)
      error_msg = "Invalid channel type: expected Channel::Instagram, got #{channel.class}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
      add_error(error_msg)
      return false
    end

    Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] Channel configuration validation passed'
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Channel ID: #{channel.id}, Class: #{channel.class}"
    true
  end

  # Validate that access token is available and not empty
  # @return [Boolean] true if access token is available, false otherwise
  def validate_access_token_availability
    Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] Validating access token availability'

    begin
      # Use the channel's access_token method which handles token refresh
      token = channel.access_token

      unless token.present?
        error_msg = "Instagram access token not available for channel #{channel.id}"
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
        add_error(error_msg)
        return false
      end

      # Basic token format validation (should be a non-empty string)
      unless token.is_a?(String) && token.length > 10
        error_msg = 'Instagram access token appears to be invalid (too short or wrong format)'
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
        add_error(error_msg)
        return false
      end

      Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] Access token validation passed'
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Token length: #{token.length} characters"
      true
    rescue StandardError => e
      error_msg = "Failed to retrieve Instagram access token: #{e.message}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
      add_error(error_msg)
      false
    end
  end

  # Validate that Instagram ID is present
  # @return [Boolean] true if Instagram ID is present, false otherwise
  def validate_instagram_id_presence
    Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] Validating Instagram ID presence'

    unless channel.instagram_id.present?
      error_msg = "Instagram ID not configured for channel #{channel.id}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
      add_error(error_msg)
      return false
    end

    # Basic Instagram ID format validation (should be numeric string)
    unless channel.instagram_id.match?(/\A\d+\z/)
      error_msg = "Instagram ID has invalid format: #{channel.instagram_id}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
      add_error(error_msg)
      return false
    end

    Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Instagram ID validation passed: #{channel.instagram_id}"
    true
  end

  # Validate that the channel token is not expired
  # @return [Boolean] true if channel is not expired, false otherwise
  def validate_channel_not_expired
    Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] Validating channel expiration status'

    if channel_expired?
      error_msg = "Instagram channel access token expired at #{channel.expires_at}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
      add_error(error_msg)
      return false
    end

    Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] Channel expiration validation passed'
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Token expires at: #{channel.expires_at}"
    true
  end

  # Check if the channel token is expired
  # @return [Boolean] true if expired, false otherwise
  def channel_expired?
    return false unless channel.expires_at.present?

    channel.expires_at <= Time.current
  end

  # Add an error to the errors collection
  # @param error_message [String] the error message to add
  def add_error(error_message)
    @errors << error_message
  end

  # Log compatibility issues for monitoring and debugging
  # @param issue_type [String] the type of compatibility issue
  # @param details [Hash] additional details about the issue
  def log_compatibility_issue(issue_type, details = {})
    Rails.logger.warn "[SOCIALWISE-INSTAGRAM-VALIDATOR] COMPATIBILITY ISSUE: #{issue_type}"
    Rails.logger.warn "[SOCIALWISE-INSTAGRAM-VALIDATOR] Details: #{details.inspect}"
    Rails.logger.warn "[SOCIALWISE-INSTAGRAM-VALIDATOR] Message ID: #{message.id}, Conversation ID: #{conversation.id}"
    Rails.logger.warn "[SOCIALWISE-INSTAGRAM-VALIDATOR] Account ID: #{conversation.account_id}, Inbox ID: #{inbox.id}"
  end

  # Perform a test API call to verify channel connectivity (optional validation)
  # This is not called by default but can be used for deeper validation
  # @return [Boolean] true if API call succeeds, false otherwise
  def test_api_connectivity
    Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] Testing Instagram API connectivity'

    begin
      # Make a simple API call to verify the token works
      response = HTTParty.get(
        "https://graph.instagram.com/v22.0/#{channel.instagram_id}",
        query: {
          fields: 'id,username',
          access_token: channel.access_token
        },
        timeout: 10
      )

      if response.success? && response.parsed_response['id'].present?
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-VALIDATOR] API connectivity test passed'
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-VALIDATOR] Instagram account: #{response.parsed_response['username']}"
        true
      else
        error_msg = "Instagram API connectivity test failed: #{response.code} - #{response.parsed_response}"
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
        add_error(error_msg)
        false
      end
    rescue StandardError => e
      error_msg = "Instagram API connectivity test failed with exception: #{e.message}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-VALIDATOR] #{error_msg}"
      add_error(error_msg)
      false
    end
  end
end
