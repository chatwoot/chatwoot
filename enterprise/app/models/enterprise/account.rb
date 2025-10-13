module Enterprise::Account
  # TODO: Remove this when we upgrade administrate gem to the latest version
  # this is a temporary method since current administrate doesn't support virtual attributes
  def manually_managed_features; end

  def mark_for_deletion(reason = 'manual_deletion')
    reason = reason.to_s == 'manual_deletion' ? 'manual_deletion' : 'inactivity'

    result = custom_attributes.merge!(
      'marked_for_deletion_at' => 7.days.from_now.iso8601,
      'marked_for_deletion_reason' => reason
    ) && save

    # Send notification to admin users if the account was successfully marked for deletion
    if result
      mailer = AdministratorNotifications::AccountNotificationMailer.with(account: self)
      if reason == 'manual_deletion'
        mailer.account_deletion_user_initiated(self, reason).deliver_later
      else
        mailer.account_deletion_for_inactivity(self, reason).deliver_later
      end
    end

    result
  end

  def unmark_for_deletion
    custom_attributes.delete('marked_for_deletion_at') && custom_attributes.delete('marked_for_deletion_reason') && save
  end

  def saml_enabled?
    saml_settings&.saml_enabled? || false
  end
end
