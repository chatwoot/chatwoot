class PaymentExpireJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
  transaction = Transaction.find_by(transaction_id: transaction_id)

  return unless transaction.present?
  return unless transaction.status == "pending"
    
  invoice_prefix = transaction_id.split('-')[1]

  ActiveRecord::Base.transaction do
    transaction.update!(status: "expired")

    user = transaction.user
        
    Rails.logger.info("PaymentExpireJob: #{invoice_prefix}")

    if ['MAU', 'AR'].include?(invoice_prefix)
      subscriptionTopup = SubscriptionTopup.find_by(duitku_order_id: transaction_id)
      subscriptionTopup.update!(status: "expired") if subscriptionTopup.present?

      case invoice_prefix
      when 'MAU'
        InvoiceMailer.mau_send_invoice_expired(
          user.email,
          user.name,
          transaction.transaction_id,
          Time.current.strftime("%-d %B %Y"),
          subscriptionTopup.payment_method == 'M2' ? 'Virtual Account' : 'Credit Card',
          transaction.price.to_i,
          subscriptionTopup.amount,
        ).deliver_later
        Rails.logger.info("Payment expired & invoice sent to #{user.email} (##{transaction.transaction_id})")
      when 'AR'
        InvoiceMailer.ai_send_invoice_expired(
          user.email,
          user.name,
          transaction.transaction_id,
          Time.current.strftime("%-d %B %Y"),
          subscriptionTopup.payment_method == 'M2' ? 'Virtual Account' : 'Credit Card',
          transaction.price.to_i,
          subscriptionTopup.amount,
        ).deliver_later
        Rails.logger.info("Payment expired & invoice sent to #{user.email} (##{transaction.transaction_id})")
      end
    else
      # Update relasi jika ada
      subscription_payment = SubscriptionPayment.find_by(duitku_order_id: transaction_id)
      Rails.logger.info("PaymentExpireJob: #{subscription_payment.inspect}")
      if subscription_payment.present?
        subscription_payment.update!(status: "expired")
        Rails.logger.info("PaymentExpireJob: 1")

        subscription = Subscription.find_by(id: subscription_payment.subscription_id)
        Rails.logger.info("PaymentExpireJob-subscription: #{subscription.inspect}")
        subscription.update!(status: "expired") if subscription.present?
        Rails.logger.info("PaymentExpireJob: 2")
      end
      
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
  rescue => e
    Rails.logger.error "expired to expire transaction #{transaction_id}: #{e.message}"
    if e.respond_to?(:record) && e.record.respond_to?(:errors)
      Rails.logger.error "Validation errors: #{e.record.errors.full_messages.join(', ')}"
    end
  end
end
