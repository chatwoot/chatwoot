module MailboxSanitizer
  NULL_BYTE = "\u0000".freeze

  private

  def sanitized_message_attributes(source_id)
    {
      account_id: @conversation.account_id,
      sender: @conversation.contact,
      content: sanitize_mailbox_value(mail_content)&.truncate(150_000),
      inbox_id: @conversation.inbox_id,
      message_type: 'incoming',
      content_type: 'incoming_email',
      source_id: source_id,
      content_attributes: sanitized_content_attributes,
      created_at: mail_original_date
    }
  end

  # Without this, ActiveRecord defaults created_at to Time.current at insert
  # time. That's wrong for any mail fetched late (IMAP catching up after
  # downtime, or a manual backfill with a wider SINCE window): the message
  # and its conversation's last_activity_at end up sorted as if they just
  # arrived, instead of at their real send time.
  def mail_original_date
    processed_mail.date&.to_time || Time.current
  rescue StandardError
    Time.current
  end

  def sanitized_content_attributes
    sanitize_mailbox_value(
      email: processed_mail.serialized_data,
      cc_email: processed_mail.cc,
      bcc_email: processed_mail.bcc
    )
  end

  def sanitize_mailbox_value(value)
    return value.delete(NULL_BYTE) if value.is_a?(String)
    return value.map { |item| sanitize_mailbox_value(item) } if value.is_a?(Array)
    return value.transform_values { |item| sanitize_mailbox_value(item) } if value.is_a?(Hash)

    value
  end
end
