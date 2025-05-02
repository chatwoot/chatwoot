# frozen_string_literal: true

class Messages::ForwardedMessageContentBuilderService
  attr_reader :formatted_info, :forwarded_message, :email_data

  def initialize(formatted_info, forwarded_message, email_data)
    @formatted_info = formatted_info
    @forwarded_message = forwarded_message
    @email_data = email_data
  end

  def forwarded_header_text
    return '' unless formatted_info.values.any?

    build_header_lines.compact.join("\n")
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

    # Always use markdown conversion since it handles plain text correctly
    converted_content = Messages::ForwardedMessageFormatterService.convert_markdown_to_html(original_content)

    html_builder = Messages::ForwardedMessageHtmlBuilderService.new(formatted_info, forwarded_message, email_data)
    html_builder.html_wrapper(converted_content)
  end

  private

  def build_header_lines
    [
      "\n\n---------- Forwarded message ---------",
      ("From: #{formatted_info[:from]}" if formatted_info[:from].present?),
      ("Date: #{formatted_info[:date]}" if formatted_info[:date].present?),
      ("Subject: #{formatted_info[:subject]}" if formatted_info[:subject].present?),
      ("To: <#{formatted_info[:to]}>" if formatted_info[:to].present?),
      "\n"
    ]
  end
end
