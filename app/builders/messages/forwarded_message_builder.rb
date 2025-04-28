# Handles formatting and preparation of forwarded email messages
class Messages::ForwardedMessageBuilder
  def initialize(message_id)
    @message_id = message_id
  end

  def perform
    return {} unless @message_id
    return basic_attributes unless valid_forwarded_data?

    build_forwarded_attributes
  end

  def formatted_content(original_content = '')
    return original_content.to_s unless valid_forwarded_data?

    original_content.to_s + forwarded_header_text + forwarded_body_text
  end

  def formatted_html_content(original_content = '')
    return original_content unless valid_forwarded_data?

    html_content = convert_markdown_to_html(original_content)
    html_wrapper(html_content)
  end

  def forwarded_email_data(original_content = '')
    return {} unless valid_forwarded_data?

    data = prepare_email_data
    full_content = formatted_content(original_content)

    data['html_content'].merge!({
                                  'quoted' => strip_markdown(original_content.to_s),
                                  'reply' => full_content,
                                  'full' => formatted_html_content(original_content)
                                })

    data['text_content'].merge!({
                                  'quoted' => original_content.to_s,
                                  'reply' => full_content,
                                  'full' => full_content
                                })

    data
  end

  private

  def valid_forwarded_data?
    forwarded_message && email_data.present?
  end

  def html_wrapper(content)
    base = '<div dir="ltr">'

    if content.blank?
      "#{base}#{forwarded_header_html}#{forwarded_body_html}</div>"
    else
      "#{base}#{content}<br><br>#{forwarded_header_html}#{forwarded_body_html}</div>"
    end
  end

  def build_forwarded_attributes
    {
      content_attributes: {
        forwarded_message_id: @message_id,
        email: prepare_email_data
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
    text_content = email_data.dig('text_content', 'full')
    html_content = email_data.dig('html_content', 'full')

    if text_content.present?
      text_content
    elsif html_content.present?
      ActionView::Base.full_sanitizer.sanitize(html_content)
    else
      forwarded_message.content.to_s
    end
  end

  def forwarded_header_html
    email = extract_email(formatted_info[:from])
    name = formatted_info[:from].split(' <').first

    [
      '<div class="gmail_quote gmail_quote_container">',
      '<div dir="ltr" class="gmail_attr">---------- Forwarded message ---------<br>',
      "From: <strong class=\"gmail_sendername\" dir=\"auto\">#{name}</strong> ",
      "<span dir=\"auto\">&lt;<a href=\"mailto:#{email}\">#{email}</a>&gt;</span><br>",
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

    html = text.to_s
    html = html.gsub(/\*\*?(.*?)\*\*?/) do |m|
      m.start_with?('**') ? "<b>#{::Regexp.last_match(1)}</b>" : "<i>#{::Regexp.last_match(1)}</i>"
    end

    html.gsub(/_(.*?)_/, '<i>\1</i>')
  end

  def extract_email(from_field)
    return '' if from_field.blank?

    from_field =~ /<(.*)>/ ? ::Regexp.last_match(1) : from_field
  end

  def forwarded_message
    @forwarded_message ||= Message.find_by(id: @message_id)
  end

  def email_data
    @email_data ||= forwarded_message&.content_attributes&.dig('email')
  end

  def basic_attributes
    { content_attributes: { forwarded_message_id: @message_id } }
  end

  def formatted_info
    {
      from: parse_from_field(extract_from_field),
      date: format_date_string(email_data['date'] || ''),
      subject: email_data['subject'] || '',
      to: email_data['to']&.first || ''
    }
  end

  def extract_from_field
    email_data['from']&.first.to_s
  end

  def parse_from_field(from_field)
    return '' if from_field.blank?

    if from_field =~ /(.*)<(.*)>/
      "#{::Regexp.last_match(1).strip} <#{::Regexp.last_match(2).strip}>"
    else
      from_field
    end
  end

  def format_date_string(date_str)
    return '' if date_str.blank?

    begin
      parsed_date = DateTime.now # Use current date
      parsed_date.strftime('%a, %b %-d, %Y at %-l:%M %p')
    rescue StandardError
      date_str
    end
  end
end
