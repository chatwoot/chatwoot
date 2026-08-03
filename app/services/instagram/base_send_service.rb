class Instagram::BaseSendService < Base::SendOnChannelService # rubocop:disable Metrics/ClassLength
  pattr_initialize [:message!]

  URL_ACTION_TYPES = %w[url link].freeze

  private

  delegate :additional_attributes, to: :contact

  def perform_reply
    send_attachments if message.attachments.present?
    if generic_template_message?
      send_generic_template_message
    elsif cta_url_message?
      send_cta_url_template_message
    elsif button_template_message?
      send_button_template_message
    elsif message.content.present?
      send_content
    end
  rescue StandardError => e
    handle_error(e)
  end

  def send_attachments
    message.attachments.each do |attachment|
      send_message(attachment_message_params(attachment))
    end
  end

  def send_content
    send_message(message_params)
  end

  def send_generic_template_message
    send_message(text_message_params) if generic_template_intro_text.present?
    send_message(generic_template_message_params)
  end

  def send_button_template_message
    send_message(button_template_message_params)
  end

  def send_cta_url_template_message
    send_message(cta_url_template_message_params)
  end

  def handle_error(error)
    ChatwootExceptionTracker.new(error, account: message.account, user: message.sender).capture_exception
  end

  def message_params
    return generic_template_message_params if generic_template_message?

    text_message_params
  end

  def text_message_params
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        text: message.outgoing_content
      }
    }

    merge_human_agent_tag(params)
  end

  def generic_template_message_params
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: generic_template_elements
          }
        }
      }
    }

    merge_human_agent_tag(params)
  end

  def button_template_message_params
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'button',
            text: button_template_text,
            buttons: button_template_buttons
          }
        }
      }
    }

    merge_human_agent_tag(params)
  end

  def cta_url_template_message_params
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: [cta_url_template_element]
          }
        }
      }
    }

    merge_human_agent_tag(params)
  end

  def generic_template_elements
    Array(message.content_attributes['items']).map do |item|
      item = item.with_indifferent_access

      {
        title: item[:title],
        subtitle: item[:description],
        image_url: item[:media_url],
        default_action: generic_template_default_action(item[:actions]),
        buttons: generic_template_buttons(item[:actions])
      }.compact
    end
  end

  def generic_template_default_action(actions)
    url_action = Array(actions).find do |action|
      action = action.with_indifferent_access
      URL_ACTION_TYPES.include?(action[:type]) && (action[:uri] || action[:url]).present?
    end

    return if url_action.blank?

    url_action = url_action.with_indifferent_access
    {
      type: 'web_url',
      url: url_action[:uri] || url_action[:url]
    }
  end

  def generic_template_buttons(actions)
    Array(actions).filter_map do |action|
      action = action.with_indifferent_access

      case action[:type]
      when 'reply', 'postback'
        {
          type: 'postback',
          title: action[:text],
          payload: action[:payload]
        }
      when 'url', 'link'
        {
          type: 'web_url',
          title: action[:text],
          url: action[:uri] || action[:url]
        }
      end
    end
  end

  def button_template_buttons
    Array(message.content_attributes['buttons']).filter_map do |button|
      button = button.with_indifferent_access
      action_type = button[:type].presence || 'reply'

      case action_type
      when 'reply', 'postback'
        {
          type: 'postback',
          title: button[:text],
          payload: button[:id]
        }
      when 'url', 'link'
        {
          type: 'web_url',
          title: button[:text],
          url: button[:uri] || button[:url]
        }
      end
    end
  end

  def cta_url_template_element
    {
      title: cta_url_template_title,
      subtitle: cta_url_template_subtitle,
      image_url: cta_url_template_image_url,
      default_action: cta_url_template_default_action,
      buttons: [cta_url_template_button]
    }.compact
  end

  def cta_url_template_default_action
    {
      type: 'web_url',
      url: cta_url_button_url
    }
  end

  def cta_url_template_button
    {
      type: 'web_url',
      title: cta_url_button_text,
      url: cta_url_button_url
    }
  end

  def generic_template_message?
    message.content_type == 'cards'
  end

  def cta_url_message?
    message.content_type == 'cta_url'
  end

  def button_template_message?
    message.content_type == 'interactive_buttons'
  end

  def generic_template_intro_text
    @generic_template_intro_text ||= message.outgoing_content.presence
  end

  def button_template_text
    message.outgoing_content.presence || message.content_attributes['body_text']
  end

  def cta_url_template_title
    message.outgoing_content.presence || message.content_attributes['body_text']
  end

  def cta_url_template_subtitle
    message.content_attributes['footer_text'].presence
  end

  def cta_url_template_image_url
    message.content_attributes.dig('header', 'media_url').presence
  end

  def cta_url_button_text
    message.content_attributes.dig('action', 'text')
  end

  def cta_url_button_url
    message.content_attributes.dig('action', 'uri')
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
      Rails.logger.error("Instagram response: #{external_error} : #{parsed_response['error']} : #{message_content}")
      Messages::StatusUpdateService.new(message, 'failed', external_error).perform
      nil
    end
  end

  def external_error(response)
    error_message = response.dig('error', 'message')
    error_code = response.dig('error', 'code')

    channel.authorization_error! if error_code == 190

    "#{error_code} - #{error_message}"
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def send_message(message_content)
    raise NotImplementedError, 'Subclasses must implement send_message'
  end

  def merge_human_agent_tag(params)
    raise NotImplementedError, 'Subclasses must implement merge_human_agent_tag'
  end
end
