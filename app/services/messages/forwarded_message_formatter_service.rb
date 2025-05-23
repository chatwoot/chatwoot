# frozen_string_literal: true

class Messages::ForwardedMessageFormatterService
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

  # Convert text to plain text, stripping any markdown formatting
  def self.markdown_to_plain_text(text)
    return '' if text.blank?

    # Simply strip any markdown by converting to HTML and sanitizing
    strip_markdown(text)
  end
end
