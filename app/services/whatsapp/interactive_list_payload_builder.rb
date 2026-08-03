class Whatsapp::InteractiveListPayloadBuilder
  HEADER_TYPE = 'text'.freeze

  def initialize(message)
    @message = message
  end

  def perform
    validate_message!

    {
      type: 'list',
      header: header_payload,
      body: {
        text: body_text
      },
      footer: footer_payload,
      action: {
        button: action[:button_text],
        sections: sections_payload
      }
    }.compact
  end

  private

  attr_reader :message

  def validate_message!
    raise StandardError, 'Interactive list messages are only supported for WhatsApp inboxes' unless message.inbox.whatsapp?
    raise StandardError, 'Interactive list body text is required' if body_text.blank?
    raise StandardError, 'Interactive list action button_text is required' if action[:button_text].blank?
    raise StandardError, 'Interactive list sections are required' if sections.blank?

    validate_header!
  end

  def validate_header!
    return if header.blank?

    raise StandardError, 'Interactive list header type must be text' if header[:type] != HEADER_TYPE
    raise StandardError, 'Interactive list header text is required' if header[:text].blank?
  end

  def body_text
    content_attributes[:body_text].presence || message.outgoing_content
  end

  def header_payload
    return if header.blank?

    {
      type: HEADER_TYPE,
      text: header[:text]
    }
  end

  def footer_payload
    return if footer_text.blank?

    {
      text: footer_text
    }
  end

  def sections_payload
    sections.map do |section|
      section = ensure_indifferent_access(section)
      {
        title: section[:title],
        rows: Array(section[:rows]).map do |row|
          row = ensure_indifferent_access(row)
          {
            id: row[:id],
            title: row[:title],
            description: row[:description]
          }.compact
        end
      }.compact
    end
  end

  def sections
    @sections ||= Array(content_attributes[:sections])
  end

  def header
    @header ||= ensure_indifferent_access(content_attributes[:header])
  end

  def action
    @action ||= ensure_indifferent_access(content_attributes[:action])
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
end
