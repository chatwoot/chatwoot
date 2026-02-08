module Enterprise::Account
  # TODO: Remove this when we upgrade administrate gem to the latest version
  # this is a temporary method since current administrate doesn't support virtual attributes
  def manually_managed_features; end

  def mark_for_deletion(reason = 'manual_deletion')
    result = custom_attributes.merge!('marked_for_deletion_at' => 7.days.from_now.iso8601, 'marked_for_deletion_reason' => reason) && save

    # Send notification to admin users if the account was successfully marked for deletion
    AdministratorNotifications::AccountNotificationMailer.with(account: self).account_deletion(self, reason).deliver_later if result

    result
  end

  def unmark_for_deletion
    custom_attributes.delete('marked_for_deletion_at') && custom_attributes.delete('marked_for_deletion_reason') && save
  end
end
