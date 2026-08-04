class Whatsapp::CtaUrlPayloadBuilder
  HEADER_TYPE = 'image'.freeze

  def initialize(message)
    @message = message
  end

  def perform
    validate_message!

    {
      type: 'cta_url',
      header: header_payload,
      body: {
        text: body_text
      },
      action: {
        name: 'cta_url',
        parameters: {
          display_text: action[:text],
          url: action[:uri]
        }
      },
      footer: footer_payload
    }.compact
  end

  private

  attr_reader :message

  def validate_message!
    unless message.inbox.whatsapp?
      raise CustomExceptions::Whatsapp::InvalidInteractivePayload,
            'Interactive CTA URL messages are only supported for WhatsApp inboxes'
    end
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'CTA URL body text is required' if body_text.blank?
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'CTA URL action text is required' if action[:text].blank?
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'CTA URL action uri is required' if action[:uri].blank?

    validate_header!
  end

  def validate_header!
    return if header.blank?

    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'CTA URL header type must be image' if header[:type] != HEADER_TYPE
    raise CustomExceptions::Whatsapp::InvalidInteractivePayload, 'CTA URL header media_url is required' if header[:media_url].blank?
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

  def body_text
    content_attributes[:body_text].presence || message.outgoing_content
  end

  def footer_text
    content_attributes[:footer_text]
  end

  def header
    @header ||= ensure_indifferent_access(content_attributes[:header])
  end

  def action
    @action ||= ensure_indifferent_access(content_attributes[:action])
  end

  def content_attributes
    @content_attributes ||= ensure_indifferent_access(message.content_attributes)
  end

  def ensure_indifferent_access(value)
    value.is_a?(Hash) ? value.with_indifferent_access : {}
  end
end
