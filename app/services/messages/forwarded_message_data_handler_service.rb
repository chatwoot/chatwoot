# frozen_string_literal: true

class Messages::ForwardedMessageDataHandlerService
  attr_reader :forwarded_message, :email_data, :params

  def initialize(forwarded_message, email_data, params = {})
    @forwarded_message = forwarded_message
    @email_data = email_data
    @params = params || {}
  end

  def prepare_email_data
    initialize_email_data
  end

  def formatted_info
    {
      from: inbox_email.to_s,
      date: Messages::ForwardedMessageFormatterService.format_date_string(email_date),
      subject: subject.to_s,
      to: recipient_email.to_s
    }
  end

  private

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
    data['to'] = Array(params[:to_emails]) if params && params[:to_emails].present?
    data['subject'] ||= subject
    data['date'] ||= Time.zone.now.to_s
  end

  def inbox_email
    email_from_data || email_from_inbox
  end

  def email_from_data
    return nil unless email_data_has_from?

    from_field = email_data['from'].first.to_s
    Messages::ForwardedMessageFormatterService.parse_from_field(from_field)
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
