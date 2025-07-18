class Instagram::BaseSendService < Base::SendOnChannelService
  pattr_initialize [:message!]

  private

  delegate :additional_attributes, to: :contact

  def perform_reply
    send_attachments if message.attachments.present?
    send_content if message.content.present?
  rescue StandardError => e
    handle_error(e)
  end

  def send_attachments
    message.attachments.each do |attachment|
      send_message(attachment_message_params(attachment))
    end
  end

  def send_content
    params = if message.content_type == 'cards'
               carousel_message_params
             else
               message_params
             end
    send_message(params)
  end

  def handle_error(error)
    ChatwootExceptionTracker.new(error, account: message.account, user: message.sender).capture_exception
  end

  def message_params
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        text: message.outgoing_content
      }
    }

    merge_human_agent_tag(params)
  end

  def carousel_message_params
    elements = build_carousel_elements
    
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: elements
          }
        }
      }
    }
    
    # Log the payload for debugging
    Rails.logger.info("Instagram Carousel Payload: #{params.to_json}")
    
    merge_human_agent_tag(params)
  end

  def build_carousel_elements
    return [] unless message.content_attributes['items'].present?

    message.content_attributes['items'].filter_map do |item|
      next unless item['title'].present?

      element = {
        title: item['title'].to_s.truncate(80),
        subtitle: item['description'].to_s.truncate(80),
        image_url: item['media_url']
      }

      if item['actions'].present?
        buttons = build_carousel_buttons(item['actions'])
        element[:buttons] = buttons if buttons.present?

        first_link_action = item['actions'].find { |a| a['type'] == 'link' }
        if first_link_action && first_link_action['uri'].present?
          element[:default_action] = {
            type: 'web_url',
            url: first_link_action['uri']
          }
        end
      end

      element
    end
  end

  def build_carousel_buttons(actions)
    return [] if actions.blank?

    actions.first(3).filter_map do |action|
      next unless action.is_a?(Hash) && action['type'].present? && action['text'].present?

      case action['type']
      when 'link'
        next unless action['uri'].present?
        {
          type: 'web_url',
          title: action['text'].to_s.truncate(20),
          url: action['uri'].to_s
        }
      when 'postback'
        next unless action['payload'].present?
        {
          type: 'postback',
          title: action['text'].to_s.truncate(20),
          payload: action['payload'].to_s.truncate(1000)
        }
      end
    end
  end

  def attachment_message_params(attachment)
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      }
    }

    merge_human_agent_tag(params)
  end

  def process_response(response, message_content)
    parsed_response = response.parsed_response
    if response.success? && parsed_response['error'].blank?
      message.update!(source_id: parsed_response['message_id'])
      parsed_response
    else
      external_error = external_error(parsed_response)
      Rails.logger.error("Instagram response: #{external_error} : #{message_content}")
      Messages::StatusUpdateService.new(message, 'failed', external_error).perform
      nil
    end
  end

  def external_error(response)
    error_message = response.dig('error', 'message')
    error_code = response.dig('error', 'code')

    # https://developers.facebook.com/docs/messenger-platform/error-codes
    # Access token has expired or become invalid. This may be due to a password change,
    # removal of the connected app from Instagram account settings, or other reasons.
    channel.authorization_error! if error_code == 190

    "#{error_code} - #{error_message}"
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  # Methods to be implemented by child classes
  def send_message(message_content)
    raise NotImplementedError, 'Subclasses must implement send_message'
  end

  def merge_human_agent_tag(params)
    raise NotImplementedError, 'Subclasses must implement merge_human_agent_tag'
  end
end
