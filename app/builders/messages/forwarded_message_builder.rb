module Messages::ForwardedMessageFormatter
  def self.parse_from_field(from_field)
    return '' if from_field.blank?

    from_field =~ /(.*)<(.*)>/ ? Regexp.last_match(2).strip : from_field
  end

  def self.format_plain_text_to_html(text)
    ERB::Util.html_escape(text.to_s).gsub("\n", '<br>')
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

  def self.strip_markdown(text)
    return '' if text.blank?

    # Convert markdown to HTML using CommonMarker
    html = CommonMarker.render_html(text, :DEFAULT)

    # Strip HTML tags to get plain text
    ActionView::Base.full_sanitizer.sanitize(html)
  end

  def self.convert_markdown_to_html(text)
    return '' if text.blank?

    # Use CommonMarker with GitHub Flavored Markdown options
    options = [:GITHUB_PRE_LANG, :UNSAFE]
    extensions = [:table, :strikethrough, :autolink]

    CommonMarker.render_html(text, options, extensions)
  end

  # Convert markdown to plain text without HTML intermediary
  def self.markdown_to_plain_text(text)
    return '' if text.blank?

    # If it's not markdown, return as is
    return text unless contains_markdown?(text)

    # Otherwise, strip markdown by first converting to HTML, then sanitizing
    strip_markdown(text)
  end

  # Add a helper method to detect if text contains markdown
  def self.contains_markdown?(text)
    return false if text.blank?

    # Check for common markdown patterns
    markdown_patterns = [
      /\*\*.*?\*\*/, # Bold
      /\*[^*\n]+?\*/, # Italic with asterisk
      /_[^_\n]+?_/, # Italic with underscore
      /^\s*\#{1,6}\s+/m,       # Headers
      /^\s*>\s+/m,             # Blockquotes
      /`[^`\n]+?`/,            # Inline code
      /^```/m,                 # Code blocks
      /\[[^\]\n]{0,100}\]\([^)\n]{0,300}\)/, # Links (safe)
      /^\s*[*\-+]\s+/m, # Unordered lists
      /^\s*\d+\.\s+/m,         # Ordered lists
      /^\s*\|.*\|/m,           # Tables
      /~~.*?~~/                # Strikethrough
    ]
    markdown_patterns.any? { |pattern| text =~ pattern }
  end
end

# Only modify the formatted_html_content method in ForwardedMessageContentBuilder
module Messages::ForwardedMessageContentBuilder
  def forwarded_header_text
    return '' unless formatted_info.values.any?

    build_header_lines.compact.join("\n")
  end

  def build_header_lines
    [
      "\n\n---------- Forwarded message ---------",
      ("From: #{formatted_info[:from]}" if formatted_info[:from]),
      ("Date: #{formatted_info[:date]}" if formatted_info[:date]),
      ("Subject: #{formatted_info[:subject]}" if formatted_info[:subject]),
      ("To: <#{formatted_info[:to]}>" if formatted_info[:to]),
      "\n"
    ]
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

  # Update this method to intelligently decide how to format content
  def formatted_html_content(original_content = '')
    return original_content if forwarded_message.blank?

    # Check if content contains markdown and format accordingly
    converted_content = if Messages::ForwardedMessageFormatter.contains_markdown?(original_content.to_s)
                          Messages::ForwardedMessageFormatter.convert_markdown_to_html(original_content)
                        else
                          Messages::ForwardedMessageFormatter.format_plain_text_to_html(original_content)
                        end

    html_wrapper(converted_content)
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

  # Update this method to handle markdown when appropriate
  def forwarded_body_html
    # Return HTML content directly if available
    return email_data.dig('html_content', 'full') if email_data&.dig('html_content', 'full').present?

    # Otherwise format content to HTML
    content = if email_data&.dig('text_content', 'full').present?
                email_data.dig('text_content', 'full')
              else
                forwarded_message.content.to_s
              end

    # Check if content contains markdown and format accordingly
    if Messages::ForwardedMessageFormatter.contains_markdown?(content)
      Messages::ForwardedMessageFormatter.convert_markdown_to_html(content)
    else
      Messages::ForwardedMessageFormatter.format_plain_text_to_html(content)
    end
  end
end

# The rest of the modules and class remain unchanged
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

    # Convert markdown in original_content to plain text
    original_plain = Messages::ForwardedMessageFormatter.markdown_to_plain_text(original_content.to_s)

    # Convert full_content to plain text if it contains markdown
    full_plain = Messages::ForwardedMessageFormatter.markdown_to_plain_text(full_content)

    stripped = Messages::ForwardedMessageFormatter.strip_markdown(original_content.to_s)
    html_full = formatted_html_content(original_content)

    data['html_content'].merge!('quoted' => stripped, 'reply' => full_content, 'full' => html_full)

    data['text_content'].merge!(
      'quoted' => original_plain,
      'reply' => full_plain,
      'full' => full_plain
    )

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
