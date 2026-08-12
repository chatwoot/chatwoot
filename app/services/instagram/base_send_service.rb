class Instagram::BaseSendService < Base::SendOnChannelService # rubocop:disable Metrics/ClassLength
  pattr_initialize [:message!]

  URL_ACTION_TYPES = %w[url link].freeze
  # Messenger's generic template limits both title and subtitle to 80 characters;
  # our forms allow much longer body/footer text (e.g. up to 1024 characters).
  GENERIC_TEMPLATE_TEXT_MAX_LENGTH = 80

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

  # A cards message with intro text is two independent provider requests for one
  # Chatwoot message. If one half succeeds and the other fails, a Retry must not
  # replay the half that already reached the recipient, so track each part's
  # completion in content_attributes and skip parts already sent.
  def send_generic_template_message
    if generic_template_intro_text.present? && message.content_attributes['generic_template_intro_sent'].blank?
      # Don't let the intro-text half set source_id: the base service treats a
      # present source_id as "already sent by this channel" and would silently
      # skip a Retry before the cards half ever got a chance to complete.
      # process_response returns nil on failure, so its truthiness (not
      # message.status, which a later success won't reset) tells us whether
      # this specific send succeeded.
      return unless send_message(text_message_params, update_source_id: false)

      mark_generic_template_part_sent('generic_template_intro_sent')
    end

    return if message.content_attributes['generic_template_cards_sent'].present?

    mark_generic_template_part_sent('generic_template_cards_sent') if send_message(generic_template_message_params)
  end

  def mark_generic_template_part_sent(key)
    message.content_attributes[key] = true
    message.save!
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
        title: truncate_for_generic_template(item[:title]),
        subtitle: truncate_for_generic_template(item[:description]),
        image_url: item[:media_url],
        default_action: generic_template_default_action(item[:actions]),
        buttons: generic_template_buttons(item[:actions])
      }.compact
    end
  end

  def truncate_for_generic_template(text)
    text.to_s.strip.first(GENERIC_TEMPLATE_TEXT_MAX_LENGTH).presence
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
          payload: Messages::PostbackPayloadCodec.encode(message.id, action[:payload])
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
          payload: Messages::PostbackPayloadCodec.encode(message.id, button[:id])
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
    truncate_for_generic_template(message.outgoing_content.presence || message.content_attributes['body_text'])
  end

  def cta_url_template_subtitle
    truncate_for_generic_template(message.content_attributes['footer_text'])
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

  def process_response(response, message_content, update_source_id: true)
    parsed_response = response.parsed_response
    if response.success? && parsed_response['error'].blank?
      if update_source_id
        track_additional_source_id
        message.update!(source_id: parsed_response['message_id'])
      else
        # The intro-text half of a multi-part send must not become source_id (see
        # send_generic_template_message), but its MID still needs to be remembered
        # so the inbound webhook echo for it can be matched and deduped.
        remember_additional_source_id(parsed_response['message_id'])
        message.save!
      end
      parsed_response
    else
      external_error = external_error(parsed_response)
      Rails.logger.error("Instagram response: #{external_error} : #{parsed_response['error']} : #{message_content}")
      Messages::StatusUpdateService.new(message, 'failed', external_error).perform
      nil
    end
  end

  # A multi-part card send (intro text + generic template) issues two provider
  # sends for the same Chatwoot message, and each success overwrites source_id,
  # so the first send's MID would otherwise be lost. Keep it around so the
  # inbound webhook echo for that MID can still be matched and deduped.
  def track_additional_source_id
    remember_additional_source_id(message.source_id)
  end

  def remember_additional_source_id(source_id)
    return if source_id.blank?

    additional_source_ids = Array(message.content_attributes['additional_source_ids'])
    message.content_attributes['additional_source_ids'] = (additional_source_ids + [source_id]).uniq
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

  def send_message(message_content, update_source_id: true)
    raise NotImplementedError, 'Subclasses must implement send_message'
  end

  def merge_human_agent_tag(params)
    raise NotImplementedError, 'Subclasses must implement merge_human_agent_tag'
  end
end
