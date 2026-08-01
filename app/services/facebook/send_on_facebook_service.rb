class Facebook::SendOnFacebookService < Base::SendOnChannelService
  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    if generic_template_message?
      send_generic_template_message
    elsif cta_url_message?
      send_cta_url_generic_template_message
    elsif button_template_message?
      send_button_generic_template_message
    else
      send_message_to_facebook fb_text_message_params if message.content.present?

      if message.attachments.present?
        message.attachments.each do |attachment|
          send_message_to_facebook fb_attachment_message_params(attachment)
        end
      end
    end
  rescue Facebook::Messenger::FacebookError => e
    handle_facebook_error(e)
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def send_message_to_facebook(delivery_params)
    parsed_result = deliver_message(delivery_params)
    return if parsed_result.nil?

    if parsed_result['error'].present?
      Messages::StatusUpdateService.new(message, 'failed', external_error(parsed_result)).perform
      Rails.logger.info "Facebook::SendOnFacebookService: Error sending message to Facebook : Page - #{channel.page_id} : #{parsed_result}"
    end

    message.update!(source_id: parsed_result['message_id']) if parsed_result['message_id'].present?
  end

  def deliver_message(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    JSON.parse(result)
  rescue JSON::ParserError
    Messages::StatusUpdateService.new(message, 'failed', 'Facebook was unable to process this request').perform
    Rails.logger.error "Facebook::SendOnFacebookService: Error parsing JSON response from Facebook : Page - #{channel.page_id} : #{result}"
    nil
  rescue Net::OpenTimeout
    Messages::StatusUpdateService.new(message, 'failed', 'Request timed out, please try again later').perform
    Rails.logger.error "Facebook::SendOnFacebookService: Timeout error sending message to Facebook : Page - #{channel.page_id}"
    nil
  end

  def fb_text_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: fb_text_message_payload
    }.merge(messaging_type_params)
  end

  def fb_generic_template_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: fb_generic_template_elements
          }
        }
      }
    }.merge(messaging_type_params)
  end

  def fb_text_message_payload
    if message.content_type == 'input_select' && message.content_attributes['items'].any?
      {
        text: message.content,
        quick_replies: message.content_attributes['items'].map do |item|
          {
            content_type: 'text',
            payload: item['title'],
            title: item['title']
          }
        end
      }
    else
      { text: message.outgoing_content }
    end
  end

  def send_generic_template_message
    send_message_to_facebook(fb_text_message_params) if generic_template_intro_text.present?
    send_message_to_facebook(fb_generic_template_message_params)
  end

  def send_button_generic_template_message
    send_message_to_facebook(fb_button_generic_template_message_params)
  end

  def send_cta_url_generic_template_message
    send_message_to_facebook(fb_cta_url_generic_template_message_params)
  end

  def fb_generic_template_elements
    Array(message.content_attributes['items']).map do |item|
      item = item.with_indifferent_access

      {
        title: item[:title],
        subtitle: item[:description],
        image_url: item[:media_url],
        buttons: fb_generic_template_buttons(item[:actions])
      }.compact
    end
  end

  def fb_generic_template_buttons(actions)
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

  def fb_button_generic_template_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: [fb_button_generic_template_element]
          }
        }
      }
    }.merge(messaging_type_params)
  end

  def fb_cta_url_generic_template_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: [fb_cta_url_generic_template_element]
          }
        }
      }
    }.merge(messaging_type_params)
  end

  def fb_button_generic_template_element
    {
      title: button_generic_template_title,
      subtitle: button_generic_template_subtitle,
      image_url: button_generic_template_image_url,
      buttons: fb_button_generic_template_buttons
    }.compact
  end

  def fb_button_generic_template_buttons
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

  def fb_cta_url_generic_template_element
    {
      title: cta_url_template_text,
      subtitle: cta_url_template_footer,
      image_url: cta_url_template_image_url,
      default_action: fb_cta_url_default_action,
      buttons: [fb_cta_url_button]
    }.compact
  end

  def fb_cta_url_default_action
    {
      type: 'web_url',
      url: cta_url_button_url
    }
  end

  def fb_cta_url_button
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

  def button_generic_template_title
    button_template_text
  end

  def button_generic_template_subtitle
    message.content_attributes['footer_text'].presence
  end

  def button_generic_template_image_url
    message.content_attributes.dig('header', 'media_url').presence
  end

  def cta_url_template_text
    message.outgoing_content.presence || message.content_attributes['body_text']
  end

  def cta_url_template_footer
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

  def external_error(response)
    error_message = response['error']['message']
    error_code = response['error']['code']

    "#{error_code} - #{error_message}"
  end

  def fb_attachment_message_params(attachment)
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      }
    }.merge(messaging_type_params)
  end

  def messaging_type_params
    if within_24_hour_window?
      { messaging_type: 'RESPONSE' }
    elsif GlobalConfigService.load('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT', nil)
      { messaging_type: 'MESSAGE_TAG', tag: 'HUMAN_AGENT' }
    else
      { messaging_type: 'RESPONSE' }
    end
  end

  def within_24_hour_window?
    last_incoming = conversation.messages.where(account_id: conversation.account_id).incoming.last
    last_incoming.present? && Time.current < last_incoming.created_at + 24.hours
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def handle_facebook_error(exception)
    return unless exception.to_s.include?('The session has been invalidated') || exception.to_s.include?('Error validating access token')

    channel.authorization_error!
  end
end
