module IncomingEmailValidityHelper
  private

  def incoming_email_from_valid_email?
    return false unless valid_external_email_for_active_account?

    # we skip processing auto reply emails like delivery status notifications
    # out of office replies, etc.
    return false if auto_reply_email?

    # return if email doesn't have a valid sender
    # This can happen in cases like bounce emails for invalid contact email address
    # TODO: Handle the bounce separately and mark the contact as invalid in case of reply bounces
    # The returned value could be "\"\"" for some email clients
    return false unless Devise.email_regexp.match?(@processed_mail.original_sender)

    true
  end

  def valid_external_email_for_active_account?
    return false unless @account.active?
    return false if @processed_mail.notification_email_from_chatwoot?

    true
  end

  def auto_reply_email?
    if @processed_mail.auto_reply?
      Rails.logger.info "is_auto_reply? : #{processed_mail.auto_reply?}"
      true
    else
      false
    end
  end
end
