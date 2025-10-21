module IncomingEmailValidityHelper
  private

  def incoming_email_from_valid_email?
    return false unless valid_external_email_for_active_account?

    # Return if email doesn't have a valid sender
    # This can happen in cases like bounce emails for invalid contact email address
    return false unless Devise.email_regexp.match?(@processed_mail.original_sender)

    true
  end

  def valid_external_email_for_active_account?
    return false unless @account.active?
    return false if @processed_mail.notification_email_from_chatwoot?

    true
  end
end
