# frozen_string_literal: true

class Messages::ForwardedMessageBuilderService
  attr_reader :message_id, :params

  def initialize(message_id, params = {})
    @message_id = message_id
    @params = params || {}
  end

  def perform
    return {} unless message_id
    return basic_attributes if forwarded_message.blank?

    build_forwarded_attributes
  end

  def formatted_content(original_content = '')
    return original_content.to_s if forwarded_message.blank?

    data_handler = Messages::ForwardedMessageDataHandlerService.new(forwarded_message, email_data, params)
    formatted_info = data_handler.formatted_info

    content_builder = Messages::ForwardedMessageContentBuilderService.new(
      formatted_info,
      forwarded_message,
      email_data
    )

    content_builder.formatted_content(original_content)
  end

  def forwarded_email_data(original_content = '')
    return {} if forwarded_message.blank?

    data_handler = Messages::ForwardedMessageDataHandlerService.new(forwarded_message, email_data, params)
    data = data_handler.prepare_email_data
    formatted_info = data_handler.formatted_info

    content_builder = Messages::ForwardedMessageContentBuilderService.new(
      formatted_info,
      forwarded_message,
      email_data
    )

    process_email_content(data, content_builder, original_content)
  end

  def forwarded_attachments
    forwarded_message.attachments if forwarded_message&.attachments.present?
  end

  private

  def process_email_content(data, content_builder, original_content)
    full_content = content_builder.formatted_content(original_content)
    process_text_content(data, original_content, full_content)
    process_html_content(data, content_builder, original_content, full_content)
    add_attachments(data)
    data
  end

  def process_text_content(data, original_content, full_content)
    # Convert markdown in original_content to plain text
    original_plain = Messages::ForwardedMessageFormatterService.markdown_to_plain_text(original_content.to_s)

    # Convert full_content to plain text if it contains markdown
    full_plain = Messages::ForwardedMessageFormatterService.markdown_to_plain_text(full_content)

    data['text_content'].merge!(
      'quoted' => original_plain,
      'reply' => full_plain,
      'full' => full_plain
    )
  end

  def process_html_content(data, content_builder, original_content, full_content)
    stripped = Messages::ForwardedMessageFormatterService.strip_markdown(original_content.to_s)
    html_full = content_builder.formatted_html_content(original_content)

    data['html_content'].merge!(
      'quoted' => stripped,
      'reply' => full_content,
      'full' => html_full
    )
  end

  def add_attachments(data)
    return if forwarded_message.attachments.blank?

    data['attachments'] = forwarded_message.attachments.map(&:serializable_hash)
  end

  def build_forwarded_attributes
    { content_attributes: { forwarded_message_id: message_id, email: prepare_email_data } }
  end

  def prepare_email_data
    data_handler = Messages::ForwardedMessageDataHandlerService.new(forwarded_message, email_data, params)
    data_handler.prepare_email_data
  end

  def forwarded_message
    @forwarded_message ||= Message.find_by(id: message_id)
  end

  def email_data
    @email_data ||= forwarded_message&.content_attributes&.dig('email')
  end

  def basic_attributes
    { content_attributes: { forwarded_message_id: message_id } }
  end
end
