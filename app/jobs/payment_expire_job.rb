class PaymentExpireJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
  transaction = Transaction.find_by(id: transaction_id)
  return unless transaction.present?
  return unless transaction.status == "pending"

  ActiveRecord::Base.transaction do
    transaction.update!(status: "failed")

    # Update relasi jika ada
    subscription_payment = SubscriptionPayment.find_by(duitku_order_id: transaction_id)
    if subscription_payment.present?
      subscription_payment.update!(status: "failed")

      subscription = Subscription.find_by(id: subscription_payment.subscription_id)
      subscription.update!(status: "failed") if subscription.present?
    end

    user = transaction.user
    InvoiceMailer.send_invoice_expired(
      user.email,
      user.name,
      transaction.transaction_id,
      Time.current.strftime("%-d %B %Y"),
      transaction.price.to_i,
      transaction.package_name,
    ).deliver_later
    Rails.logger.info("Payment expired & invoice sent to #{user.email} (##{transaction.transaction_id})")
  end
  rescue => e
    Rails.logger.error "Failed to expire transaction #{transaction_id}: #{e.message}"
    # Tambahkan notifikasi error ke sentry atau monitoring jika perlu
  end
end
