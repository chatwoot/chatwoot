# Handles formatting and preparation of forwarded email messages
class Messages::ForwardedMessageBuilder
  def initialize(message_id)
    @message_id = message_id
  end

  def perform
    return {} unless @message_id
    return basic_attributes unless forwarded_message && email_data.present?

    build_forwarded_attributes
  end

  def formatted_content(original_content = '')
    return original_content unless forwarded_message && email_data.present?

    original_content = original_content.to_s
    original_content + forwarded_header_text + forwarded_body_text
  end

  def formatted_html_content(original_content = '')
    return original_content unless forwarded_message && email_data.present?

    html_content = convert_markdown_to_html(original_content)

    # Ensure valid HTML structure even with empty content
    return "<div dir=\"ltr\">#{forwarded_header_html}#{forwarded_body_html}</div>" if html_content.blank?

    "<div dir=\"ltr\">#{html_content}<br><br>#{forwarded_header_html}#{forwarded_body_html}</div>"
  end

  def forwarded_email_data(original_content = '')
    return {} unless forwarded_message && email_data.present?

    original_plain = strip_markdown(original_content.to_s)
    full_content = formatted_content(original_content)

    data = prepare_email_data

    # HTML content - ensure quoted section is always included even if empty
    data['html_content']['quoted'] = original_plain
    data['html_content']['reply'] = full_content
    data['html_content']['full'] = formatted_html_content(original_content)

    # Text content - ensure quoted section is always included even if empty
    data['text_content']['quoted'] = original_content.to_s
    data['text_content']['reply'] = full_content
    data['text_content']['full'] = full_content

    data
  end

  private

  def build_forwarded_attributes
    {
      content_attributes: {
        forwarded_message_id: @message_id,
        email: prepare_email_data
        # forwarded_info: formatted_info,
      }
    }
  end

  def forwarded_header_text
    [
      "\n\n---------- Forwarded message ---------",
      "From: #{formatted_info[:from]}",
      "Date: #{formatted_info[:date]}",
      "Subject: #{formatted_info[:subject]}",
      "To: <#{formatted_info[:to]}>\n\n"
    ].join("\n")
  end

  def forwarded_body_text
    if email_data.dig('text_content', 'full').present?
      email_data.dig('text_content', 'full')
    elsif email_data.dig('html_content', 'full').present?
      ActionView::Base.full_sanitizer.sanitize(email_data.dig('html_content', 'full'))
    else
      forwarded_message.content.to_s
    end
  end

  def forwarded_header_html
    [
      '<div class="gmail_quote gmail_quote_container">',
      '<div dir="ltr" class="gmail_attr">---------- Forwarded message ---------<br>',
      "From: <strong class=\"gmail_sendername\" dir=\"auto\">#{formatted_info[:from].split(' <').first}</strong> ",
      "<span dir=\"auto\">&lt;<a href=\"mailto:#{extract_email(formatted_info[:from])}\">#{extract_email(formatted_info[:from])}</a>&gt;</span><br>",
      "Date: #{formatted_info[:date]}<br>",
      "Subject: #{formatted_info[:subject]}<br>",
      "To: &lt;<a href=\"mailto:#{formatted_info[:to]}\">#{formatted_info[:to]}</a>&gt;<br>",
      '</div><br><br>'
    ].join
  end

  def forwarded_body_html
    if email_data.dig('html_content', 'full').present?
      email_data.dig('html_content', 'full')
    elsif email_data.dig('text_content', 'full').present?
      "<pre>#{ERB::Util.html_escape(email_data.dig('text_content', 'full'))}</pre>"
    else
      "<pre>#{ERB::Util.html_escape(forwarded_message.content.to_s)}</pre>"
    end
  end

  def prepare_email_data
    data = email_data.dup || {}
    data['html_content'] ||= {}
    data['text_content'] ||= {}
    data
  end

  def strip_markdown(text)
    return '' if text.blank?

    text.gsub(/\*\*?(.*?)\*\*?|_(.*?)_/) { |_m| ::Regexp.last_match(1) || ::Regexp.last_match(2) }
  end

  def convert_markdown_to_html(text)
    return '' if text.blank?

    # Basic markdown conversion
    html = text.to_s
    # Convert *text* to <b>text</b>
    html = html.gsub(/\*\*?(.*?)\*\*?/) { |m| m.start_with?('**') ? "<b>#{::Regexp.last_match(1)}</b>" : "<i>#{::Regexp.last_match(1)}</i>" }
    # Convert _text_ to <i>text</i>
    html.gsub(/_(.*?)_/, '<i>\1</i>')
  end

  def extract_email(from_field)
    return '' if from_field.blank?

    if from_field =~ /<(.*)>/
      ::Regexp.last_match(1)
    else
      from_field
    end
  end

  def forwarded_message
    @forwarded_message ||= Message.find_by(id: @message_id)
  end

  def email_data
    @email_data ||= forwarded_message&.content_attributes&.dig('email')
  end

  def basic_attributes
    { content_attributes: { forwarded_message_id: @message_id, is_forwarded_message: true } }
  end

  def formatted_info
    {
      from: format_from_field,
      date: format_date_field,
      subject: email_data['subject'] || '',
      to: email_data['to']&.first || ''
    }
  end

  def format_from_field
    from_field = extract_from_field
    parse_from_field(from_field)
  end

  def extract_from_field
    email_data['from']&.first.to_s
  end

  def parse_from_field(from_field)
    return '' if from_field.blank?

    if from_field =~ /(.*)<(.*)>/
      name = ::Regexp.last_match(1).strip
      email = ::Regexp.last_match(2).strip
      "#{name} <#{email}>"
    else
      from_field
    end
  end

  def format_date_field
    date_str = extract_date_string
    format_date_string(date_str)
  end

  def extract_date_string
    email_data['date'] || ''
  end

  def format_date_string(date_str)
    return '' if date_str.blank?

    parsed_date = parse_date(date_str)

    if parsed_date
      parsed_date.strftime('%a, %b %d, %Y at %l:%M %p')
    else
      date_str
    end
  end

  def parse_date(date_str)
    return nil if date_str.blank?

    DateTime.parse(date_str)
  rescue StandardError
    nil
  end
end
