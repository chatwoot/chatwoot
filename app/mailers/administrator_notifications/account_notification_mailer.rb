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

  def order_paid(order, to_email)
    subject = "New Order Paid - ##{order.external_payment_id}"
    action_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/orders"

    send_notification(subject, to: to_email, action_url: action_url, meta: order_paid_meta(order))
  end

  def payment_link_paid(payment_link, to_email)
    subject = "Payment Received - ##{payment_link.external_payment_id}"
    action_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/payment-links"

    send_notification(subject, to: to_email, action_url: action_url, meta: payment_link_paid_meta(payment_link))
  end

  private

  def order_paid_meta(order)
    {
      'order_id' => order.external_payment_id,
      'contact_name' => order.contact&.name.to_s,
      'contact_phone' => order.contact&.phone_number.to_s,
      'total' => order.total.to_s,
      'currency' => order.currency,
      'paid_at' => order.paid_at&.strftime('%B %d, %Y %H:%M') || Time.current.strftime('%B %d, %Y %H:%M'),
      'items' => format_order_items(order)
    }
  end

  def format_order_items(order)
    order.order_items.includes(:product).map do |item|
      "#{item.quantity}x #{item.product.title_en} — #{item.unit_price} #{order.currency}"
    end.join(', ')
  end

  def payment_link_paid_meta(payment_link)
    {
      'payment_id' => payment_link.external_payment_id,
      'amount' => payment_link.amount.to_s,
      'currency' => payment_link.currency,
      'provider' => payment_link.provider.titleize,
      'paid_at' => payment_link.paid_at&.strftime('%B %d, %Y %H:%M') || Time.current.strftime('%B %d, %Y %H:%M')
    }.merge(payment_link_contact_meta(payment_link))
  end

  def payment_link_contact_meta(payment_link)
    {
      'contact_name' => payment_link.contact&.name.to_s,
      'contact_email' => payment_link.contact&.email.to_s,
      'contact_phone' => payment_link.contact&.phone_number.to_s,
      'conversation_id' => payment_link.conversation&.display_id.to_s,
      'created_by' => payment_link.created_by&.name.to_s
    }
  end

  def format_deletion_date(deletion_date_str)
    return 'Unknown' if deletion_date_str.blank?

    Time.zone.parse(deletion_date_str).strftime('%B %d, %Y')
  rescue StandardError
    'Unknown'
  end
end
