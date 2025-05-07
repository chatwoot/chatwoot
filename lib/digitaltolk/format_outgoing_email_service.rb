class Digitaltolk::FormatOutgoingEmailService
  attr_accessor :message

  def initialize(message)
    @message = message
  end

  def perform
    return unless message
    return unless message.message_type == 'outgoing'
    return if message.email.present?

    format_outgoing_email
  end

  private

  def format_outgoing_email
    # rubocop:disable Rails/SkipsModelValidations
    message.update_column(:content_attributes, content_attributes)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def content_attributes
    message.content_attributes.merge(email: formatted_email_data)
  end

  def formatted_email_data
    (message.email || {}).merge(formatted_email)
  end

  def formatted_email
    {
      html_content: html_content,
      text_content: text_content
    }
  end

  def mail_content
    @mail_content ||= message.content.force_encoding('UTF-8')
  end

  def html_content
    encoded = convert_escaped_text(mail_content)
    rendered_markdown = ChatwootMarkdownRenderer.new(encoded).render_article
    @decoded_html_content = ::HtmlParser.new(rendered_markdown).filtered_html
    return {} if @decoded_html_content.blank?

    body = EmailReplyTrimmer.trim(@decoded_html_content)

    @html_content ||= {
      full: rendered_markdown,
      reply: @decoded_html_content,
      quoted: body
    }
  end

  def text_content
    @decoded_text_content = mail_content
    body = EmailReplyTrimmer.trim(@decoded_text_content)
    return {} if @decoded_text_content.blank?

    @text_content ||= {
      full: @decoded_text_content,
      reply: @decoded_text_content,
      quoted: body
    }
  end

  def convert_escaped_text(content)
    content.to_s.gsub("\n", '<br/>').html_safe
  end
end
