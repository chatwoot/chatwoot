# frozen_string_literal: true

# Detects email addresses in incoming messages and saves them to the contact
# if the contact doesn't already have an email.
class ContactEmailDetectionListener < BaseListener
  EMAIL_REGEX = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/

  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless should_process?(message)

    email = message.content&.match(EMAIL_REGEX)&.to_s
    return if email.blank?

    contact = message.conversation&.contact
    return if contact.blank?
    return if contact.email.present?

    contact.update(email: email)
  end

  private

  def should_process?(message)
    message.incoming? && message.content.present?
  end
end
