# frozen_string_literal: true

class Facebook::RichMessageService
  pattr_initialize [:message!, :rich_payload!]

  def perform
    Rails.logger.info '[SOCIALWISE-FACEBOOK-RICH] === STARTING PERFORM ==='
    Rails.logger.info "[SOCIALWISE-FACEBOOK-RICH] Message ID: #{message.id}"
    Rails.logger.info "[SOCIALWISE-FACEBOOK-RICH] Channel class: #{channel.class}"

    validator = FacebookChannelValidator.new(message)
    unless validator.valid_for_rich_messages?
      Rails.logger.warn "[SOCIALWISE-FACEBOOK-RICH] Facebook channel validation failed: #{validator.error_messages}"
      return
    end

    mirror_rich_payload_to_dashboard
    send_rich_message
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-FACEBOOK-RICH] Error during perform: #{e.class}: #{e.message}"
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  private

  delegate :conversation, to: :message

  def inbox
    conversation.inbox
  end

  def channel
    inbox.channel
  end

  def contact
    conversation.contact
  end

  def recipient_id
    contact.get_source_id(inbox.id)
  end

  def send_rich_message
    params = rich_message_params
    Rails.logger.info "[SOCIALWISE-FACEBOOK-RICH] Delivering: #{params.inspect}"
    parsed = deliver_message(params)
    message.update!(source_id: parsed['message_id']) if parsed && parsed['message_id']
    parsed
  end

  def deliver_message(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    JSON.parse(result)
  rescue JSON::ParserError
    Messages::StatusUpdateService.new(message, 'failed', 'Facebook was unable to process this request').perform
    Rails.logger.error "[SOCIALWISE-FACEBOOK-RICH] Error parsing JSON response from Facebook : Page - #{channel.page_id}"
    nil
  rescue Net::OpenTimeout
    Messages::StatusUpdateService.new(message, 'failed', 'Request timed out, please try again later').perform
    Rails.logger.error "[SOCIALWISE-FACEBOOK-RICH] Timeout error sending message to Facebook : Page - #{channel.page_id}"
    nil
  rescue Facebook::Messenger::FacebookError => e
    Rails.logger.error "[SOCIALWISE-FACEBOOK-RICH] FacebookError: #{e.message}"
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
    nil
  end

  def rich_message_params
    {
      recipient: { id: recipient_id },
      message: build_message_content,
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  def template_format?
    %w[generic button].include?(rich_payload['template_type'])
  end

  def build_message_content
    if template_format?
      build_template_message
    else
      build_quick_replies_message
    end
  end

  def build_template_message
    case rich_payload['template_type']
    when 'generic'
      {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: build_generic_elements
          }
        }
      }
    when 'button'
      {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'button',
            text: rich_payload['text'],
            buttons: build_buttons(rich_payload['buttons'])
          }
        }
      }
    else
      raise ArgumentError, "Unknown template type: #{rich_payload['template_type']}"
    end
  end

  def build_generic_elements
    Array(rich_payload['elements']).map do |element|
      data = { title: element['title'] }
      data[:subtitle] = element['subtitle'] if element['subtitle'].present?
      data[:image_url] = element['image_url'] if element['image_url'].present?
      data[:buttons] = build_buttons(element['buttons']) if element['buttons'].present?
      data
    end
  end

  def build_buttons(buttons)
    Array(buttons).map do |button|
      data = { type: button['type'], title: button['title'] }
      if button['type'] == 'postback'
        data[:payload] = button['payload']
      elsif button['type'] == 'web_url'
        data[:url] = button['url']
      end
      data
    end
  end

  def build_quick_replies_message
    {
      text: rich_payload['text'],
      quick_replies: Array(rich_payload['quick_replies']).map do |qr|
        {
          content_type: qr['content_type'],
          title: qr['title'],
          payload: qr['payload']
        }
      end
    }
  end

  def mirror_rich_payload_to_dashboard
    # Always mirror if not already rich
    return if message_already_rich?

    mapped = Messages::InstagramRendererMapper.map(rich_payload)
    message.update_columns(
      content_type: Message.content_types[mapped.content_type],
      content_attributes: mapped.content_attributes,
      content: mapped.fallback_text,
      updated_at: Time.current
    )
    Rails.logger.info '[SOCIALWISE-FACEBOOK-RICH] Mirrored payload to dashboard as cards'
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-FACEBOOK-RICH] Mirroring failed: #{e.class}: #{e.message}"
  end

  def message_already_rich?
    %w[cards input_select].include?(message.content_type)
  end
end
