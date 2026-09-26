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
      content_attributes: sanitized_content_attributes
    }
  end

  def sanitized_content_attributes
    sanitize_mailbox_value(
      email: processed_mail.serialized_data,
      cc_email: processed_mail.cc,
      bcc_email: processed_mail.bcc
    )
  end

  # A subject longer than the jsonb attribute limit makes the conversation invalid, and the
  # mailbox then raises while saving it. That failure is invisible: the fetcher skips the UID,
  # the cursor moves past it, and every later sweep fails the same way, so the email never
  # becomes a conversation and nobody is told. Phone-composed mail reaches this by having the
  # whole message typed into the subject field.
  #
  # Truncating loses nothing. The complete subject is stored on the message itself, in
  # `content_attributes[:email][:subject]` through `MailPresenter#serialized_data`; this copy
  # only names the conversation and titles the outgoing reply.
  def sanitize_mail_subject(value)
    sanitize_mailbox_value(value)&.truncate(JsonbAttributesLengthValidator::MAX_STRING_LENGTH)
  end

  def sanitize_mailbox_value(value)
    return value.delete(NULL_BYTE) if value.is_a?(String)
    return value.map { |item| sanitize_mailbox_value(item) } if value.is_a?(Array)
    return value.transform_values { |item| sanitize_mailbox_value(item) } if value.is_a?(Hash)

    value
  end
end
