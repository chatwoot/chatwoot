class AdministratorNotifications::AccountNotificationMailer < AdministratorNotifications::BaseMailer
  def account_deletion_user_initiated(account, reason)
    subject = 'Your Chatwoot account deletion has been scheduled'
    action_url = settings_url('general')
    meta = {
      'account_name' => account.name,
      'deletion_date' => format_deletion_date(account.custom_attributes['marked_for_deletion_at']),
      'reason' => reason
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def account_deletion_for_inactivity(account, reason)
    subject = 'Your Chatwoot account is scheduled for deletion due to inactivity'
    action_url = settings_url('general')
    meta = {
      'account_name' => account.name,
      'deletion_date' => format_deletion_date(account.custom_attributes['marked_for_deletion_at']),
      'reason' => reason
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def contact_import_complete(resource)
    subject = 'Contact Import Completed'

    action_url = if resource.failed_records.attached?
                   Rails.application.routes.url_helpers.rails_blob_url(resource.failed_records)
                 else
                   "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{resource.account.id}/contacts"
                 end

    meta = {
      'failed_contacts' => resource.total_records - resource.processed_records,
      'imported_contacts' => resource.processed_records
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def contact_import_failed
    subject = 'Contact Import Failed'
    send_notification(subject)
  end

  def contact_export_complete(file_url, email_to)
    subject = "Your contact's export file is available to download."
    send_notification(subject, to: email_to, action_url: file_url)
  end

  def payment_links_export_complete(file_url, email_to)
    subject = 'Your payment links export file is available to download.'
    send_notification(subject, to: email_to, action_url: file_url)
  end

  def automation_rule_disabled(rule)
    subject = 'Automation rule disabled due to validation errors.'
    action_url = settings_url('automation/list')
    meta = { 'rule_name' => rule.name }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def order_paid(cart, to_email)
    subject = "New Order Paid - ##{cart.external_payment_id}"
    action_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/carts"

    send_notification(subject, to: to_email, action_url: action_url, meta: order_paid_meta(cart))
  end

  private

  def order_paid_meta(cart)
    {
      'order_id' => cart.external_payment_id,
      'contact_name' => cart.contact&.name.to_s,
      'contact_phone' => cart.contact&.phone_number.to_s,
      'total' => cart.total.to_s,
      'currency' => cart.currency,
      'paid_at' => cart.paid_at&.strftime('%B %d, %Y %H:%M') || Time.current.strftime('%B %d, %Y %H:%M'),
      'items' => format_cart_items(cart)
    }
  end

  def format_cart_items(cart)
    cart.cart_items.includes(:product).map do |item|
      "#{item.quantity}x #{item.product.title_en} — #{item.unit_price} #{cart.currency}"
    end.join(', ')
  end

  def format_deletion_date(deletion_date_str)
    return 'Unknown' if deletion_date_str.blank?

    Time.zone.parse(deletion_date_str).strftime('%B %d, %Y')
  rescue StandardError
    'Unknown'
  end
end
