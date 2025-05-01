module Messages::ForwardedMessageFormatter
  def self.parse_from_field(from_field)
    return '' if from_field.blank?

    from_field =~ /(.*)<(.*)>/ ? Regexp.last_match(2).strip : from_field
  end

  def self.format_plain_text_to_html(text)
    ERB::Util.html_escape(text.to_s).gsub("\n", '<br>')
  end

  def self.strip_markdown(text)
    return '' if text.blank?

    text.gsub(/\*\*?(.*?)\*\*?|_(.*?)_/) { |_m| Regexp.last_match(1) || Regexp.last_match(2) }
  end

  def self.convert_markdown_to_html(text)
    return '' if text.blank?

    html = text.to_s
    html.gsub!(/\*\*?(.*?)\*\*?/) do |m|
      m.start_with?('**') ? "<b>#{Regexp.last_match(1)}</b>" : "<i>#{Regexp.last_match(1)}</i>"
    end
    html.gsub(/_(.*?)_/, '<i>\1</i>')
  end

  def self.extract_email(from_field)
    return '' if from_field.blank?

    from_field =~ /<(.*)>/ ? Regexp.last_match(1) : from_field
  end

  def self.format_date_string(date_str)
    return '' if date_str.blank?

    begin
      parsed_date = DateTime.now
      parsed_date.strftime('%a, %b %-d, %Y at %-l:%M %p')
    rescue StandardError
      date_str
    end
  end
end

module Messages::ForwardedMessageHtmlBuilder
  def html_wrapper(content)
    base = '<div dir="ltr">'
    if content.blank?
      "#{base}#{forwarded_header_html}#{forwarded_body_html}</div>"
    else
      "#{base}#{content}<br><br>#{forwarded_header_html}#{forwarded_body_html}</div>"
    end
  end

  def forwarded_header_html
    from_value = formatted_info[:from].to_s
    email = Messages::ForwardedMessageFormatter.extract_email(from_value)

    [
      '<div class="gmail_quote gmail_quote_container">',
      '<div dir="ltr" class="gmail_attr">---------- Forwarded message ---------<br>',
      build_email_html(email),
      build_field_html('Date', formatted_info[:date]),
      build_field_html('Subject', formatted_info[:subject]),
      build_to_html(formatted_info[:to]),
      '</div><br><br>'
    ].compact.join
  end

  def build_email_html(email)
    return nil if email.blank?

    "From: &lt;<a href=\"mailto:#{email}\">#{email}</a>&gt;<br>"
  end

  def build_field_html(label, value)
    value.present? ? "#{label}: #{value}<br>" : nil
  end

  def build_to_html(to_email)
    return nil if to_email.blank?

    "To: &lt;<a href=\"mailto:#{to_email}\">#{to_email}</a>&gt;<br>"
  end

  def forwarded_body_html
    # Return HTML content directly if available
    return email_data.dig('html_content', 'full') if email_data&.dig('html_content', 'full').present?

    # Otherwise format plain text to HTML
    content = if email_data&.dig('text_content', 'full').present?
                email_data.dig('text_content', 'full')
              else
                forwarded_message.content.to_s
              end

    Messages::ForwardedMessageFormatter.format_plain_text_to_html(content)
  end
end

module Messages::ForwardedMessageContentBuilder
  def forwarded_header_text
    return '' unless formatted_info.values.any?

    [
      "\n\n---------- Forwarded message ---------",
      ("From: #{formatted_info[:from]}" if formatted_info[:from]),
      ("Date: #{formatted_info[:date]}" if formatted_info[:date]),
      ("Subject: #{formatted_info[:subject]}" if formatted_info[:subject]),
      ("To: <#{formatted_info[:to]}>" if formatted_info[:to]),
      "\n"
    ].compact.join("\n")
  end

  def forwarded_body_text
    return forwarded_message.content.to_s if email_data.blank?

    text = email_data.dig('text_content', 'full')
    html = email_data.dig('html_content', 'full')
    if text.present?
      text
    elsif html.present?
      ActionView::Base.full_sanitizer.sanitize(html)
    else
      forwarded_message.content.to_s
    end
  end

  def formatted_content(original_content = '')
    return original_content.to_s if forwarded_message.blank?

    original_content.to_s + forwarded_header_text + forwarded_body_text
  end

  def formatted_html_content(original_content = '')
    return original_content if forwarded_message.blank?

    html_wrapper(Messages::ForwardedMessageFormatter.convert_markdown_to_html(original_content))
  end
end

module Messages::ForwardedMessageDataHandler
  def prepare_email_data
    initialize_email_data
  end

  def initialize_email_data
    data = base_email_data
    add_content_fields(data)
    add_header_fields(data)
    data
  end

  def base_email_data
    email_data.present? ? email_data.dup || {} : {}
  end

  def add_content_fields(data)
    data['html_content'] ||= {}
    data['text_content'] ||= {}
  end

  def add_header_fields(data)
    data['from'] = [email_from_inbox] # Always overwrite with inbox email
    data['to'] = Array(@params[:to_emails]) if @params && @params[:to_emails].present?
    data['subject'] ||= subject
    data['date'] ||= Time.zone.now.to_s
  end

  def formatted_info
    {
      from: inbox_email.to_s,
      date: Messages::ForwardedMessageFormatter.format_date_string(email_date),
      subject: subject.to_s,
      to: recipient_email.to_s
    }
  end

  def inbox_email
    email_from_data || email_from_inbox
  end

  def email_from_data
    return nil unless email_data_has_from?

    from_field = email_data['from'].first.to_s
    Messages::ForwardedMessageFormatter.parse_from_field(from_field)
  end

  def email_data_has_from?
    email_data.present? &&
      email_data['from'].present? &&
      email_data['from'].first.present?
  end

  def email_from_inbox
    inbox = forwarded_message&.conversation&.inbox
    return nil if inbox.blank? || inbox.channel_type != 'Channel::Email'

    email = inbox.channel&.email
    return nil if email.blank?

    email
  end

  def recipient_email
    return email_data&.dig('to', 0) if email_data&.dig('to', 0).present?

    forwarded_message&.content_attributes&.dig('to_emails', 0).presence
  end

  def subject
    email_data&.dig('subject').presence ||
      forwarded_message&.conversation&.additional_attributes&.dig('subject').presence ||
      'No Subject'
  end

  def email_date
    email_data&.dig('date').presence || Time.zone.now.to_s
  end
end

class Messages::ForwardedMessageBuilder
  include Messages::ForwardedMessageFormatter
  include Messages::ForwardedMessageHtmlBuilder
  include Messages::ForwardedMessageContentBuilder
  include Messages::ForwardedMessageDataHandler

  def initialize(message_id, params = {})
    @message_id = message_id
    @params = params || {}
  end

  def perform
    return {} unless @message_id
    return basic_attributes if forwarded_message.blank?

    build_forwarded_attributes
  end

  def forwarded_email_data(original_content = '')
    return {} if forwarded_message.blank?

    data = prepare_email_data
    full_content = formatted_content(original_content)
    stripped = Messages::ForwardedMessageFormatter.strip_markdown(original_content.to_s)
    html_full = formatted_html_content(original_content)

    data['html_content'].merge!('quoted' => stripped, 'reply' => full_content, 'full' => html_full)
    data['text_content'].merge!('quoted' => original_content.to_s, 'reply' => full_content, 'full' => full_content)

    data['attachments'] = forwarded_message.attachments.map(&:serializable_hash) if forwarded_message.attachments.present?

    data
  end

  def forwarded_attachments
    forwarded_message.attachments if forwarded_message&.attachments&.present?
  end

  private

  def build_forwarded_attributes
    { content_attributes: { forwarded_message_id: @message_id, email: prepare_email_data } }
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
end
