class SubscriptionPaymentTimeoutJob < ApplicationJob
  queue_as :default

  def perform(*args)
    timeout_minutes = 1

    transactions = Transaction.where(status: 'pending')
               .where('expiry_date < ?', Time.current + timeout_minutes.minutes)

    transactions.find_each do |transaction|
      transaction.update(status: 'failed')

      # Update subscription_payment jika ada
      subscription_payment = SubscriptionPayment.find_by(duitku_order_id: transaction.transaction_id)
      if subscription_payment.present?
        subscription_payment.update(status: 'failed')

        # Update subscription jika ada
        subscription = Subscription.find_by(id: subscription_payment.subscription_id)
        if subscription.present?
          subscription.update(status: 'failed')

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
    end
  end
end
