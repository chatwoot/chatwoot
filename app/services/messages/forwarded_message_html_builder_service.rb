# frozen_string_literal: true

class Messages::ForwardedMessageHtmlBuilderService
  attr_reader :formatted_info, :forwarded_message, :email_data

  def initialize(formatted_info, forwarded_message, email_data)
    @formatted_info = formatted_info
    @forwarded_message = forwarded_message
    @email_data = email_data
  end

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
    email = Messages::ForwardedMessageFormatterService.extract_email(from_value)

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

  def forwarded_body_html
    # Return HTML content directly if available
    return email_data.dig('html_content', 'full') if email_data&.dig('html_content', 'full').present?

    # Otherwise format content to HTML
    content = if email_data&.dig('text_content', 'full').present?
                email_data.dig('text_content', 'full')
              else
                forwarded_message.content.to_s
              end

    # Always use markdown conversion since it handles plain text correctly
    Messages::ForwardedMessageFormatterService.convert_markdown_to_html(content)
  end

  private

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
end
