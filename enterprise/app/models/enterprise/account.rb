module Enterprise::Account
  def mark_for_deletion(reason = 'manual_deletion')
    result = custom_attributes.merge!('marked_for_deletion_at' => 7.days.from_now.iso8601, 'marked_for_deletion_reason' => reason) && save

    # Send notification to admin users if the account was successfully marked for deletion
    AdministratorNotifications::AccountNotificationMailer.with(account: self).account_deletion(self, reason).deliver_later if result

    result
  end

  def unmark_for_deletion
    custom_attributes.delete('marked_for_deletion_at') && custom_attributes.delete('marked_for_deletion_reason') && save
  end

  def ensure_stripe_customer_id
    stripe_customer = Stripe::Customer.create({
                                                description: name,
                                                name: name,
                                                email: billing_email,
                                                metadata: { account_id: id, created_at: created_at }
                                              })
    # rubocop:disable Rails/SkipsModelValidations
    update_attribute(:custom_attributes, custom_attributes.merge(stripe_customer_id: stripe_customer['id']))
    # rubocop:enable Rails/SkipsModelValidations
    stripe_customer['id']
  end

  def ensure_billing_email
    email = administrators.first.email
    # rubocop:disable Rails/SkipsModelValidations
    update_attribute(:custom_attributes, custom_attributes.merge(billing_email: email))
    # rubocop:enable Rails/SkipsModelValidations
    email
  end
end
