class Whatsapp::InteractiveButtonsPayloadBuilder
  HEADER_TYPE = 'image'.freeze
  WHATSAPP_BUTTON_TITLE_MAX_LENGTH = 20

  def initialize(message)
    @message = message
  end

  def perform
    validate_message!

    {
      type: 'button',
      header: header_payload,
      body: {
        text: body_text
      },
      footer: footer_payload,
      action: {
        buttons: buttons_payload
      }
    }.compact
  end

  private

  attr_reader :message

  def validate_message!
    unless message.inbox.whatsapp?
      raise CustomExceptions::Whatsapp::InvalidInteractivePayload,
            'Interactive buttons messages are only supported for WhatsApp inboxes'
    end
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'Interactive buttons body text is required' if body_text.blank?
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'Interactive buttons are required' if buttons.blank?
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'Interactive buttons supports at most 3 buttons' if buttons.size > 3

    validate_header!
  end

  def validate_header!
    return if header.blank?

    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'Interactive buttons header type must be image' if header[:type] != HEADER_TYPE
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'Interactive buttons header media_url is required' if header[:media_url].blank?
  end

  def body_text
    content_attributes[:body_text].presence || message.outgoing_content
  end

  def header_payload
    return if header.blank?

    {
      type: HEADER_TYPE,
      image: {
        link: header[:media_url]
      }
    }
  end

  def footer_payload
    return if footer_text.blank?

    {
      text: footer_text
    }
  end

  def buttons_payload
    buttons.map do |button|
      button = ensure_indifferent_access(button)

      {
        type: 'reply',
        reply: {
          id: button[:id],
          title: normalized_button_title(button[:text])
        }
      }
    end
  end

  def buttons
    @buttons ||= Array(content_attributes[:buttons])
  end

  def header
    @header ||= ensure_indifferent_access(content_attributes[:header])
  end

  def footer_text
    content_attributes[:footer_text]
  end

  def content_attributes
    @content_attributes ||= ensure_indifferent_access(message.content_attributes)
  end

  def ensure_indifferent_access(value)
    value.is_a?(Hash) ? value.with_indifferent_access : {}
  end

  def normalized_button_title(title)
    title.to_s.strip.first(WHATSAPP_BUTTON_TITLE_MAX_LENGTH)
  end
end
