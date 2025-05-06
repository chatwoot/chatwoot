class Api::V1::DuitkuController < Api::BaseController
  include AuthHelper
  include CacheKeysHelper
  skip_before_action :authenticate_user!
  #skip_before_action :authenticate_access_token, only: [:webhook]
  
  def webhook
    # Memvalidasi signature dari Duitku untuk keamanan
    unless valid_signature?
      render json: { error: 'Invalid signature' }, status: :unauthorized
      return
    end

    # Memproses data yang diterima dari webhook Duitku
    notification = params.permit!.to_h
    result_code = notification['resultCode']
    merchant_order_id = notification['merchantOrderId']
    email = notification['merchantUserId']
    
    # Log the notification for debugging
    Rails.logger.info("Processing Duitku webhook: #{notification.inspect}")
    
    parts = merchant_order_id.split('-')

    if parts[1] == 'TUP'
      update_subscription_topup(notification, result_code, merchant_order_id)
    else
      update_subscription_payment(notification, result_code, merchant_order_id)
    end

    render json: { success: true }
  end

  private

  def update_subscription_topup(notification, result_code, merchant_order_id)
    # Koreksi: Perubahan variabel order_id menjadi merchant_order_id
    topup = SubscriptionTopup.find_by(duitku_order_id: merchant_order_id)
    
    if topup.nil?
      Rails.logger.warn("Topup not found for order ID: #{merchant_order_id}")
      return
    end

    subscription = Subscription.find_by(id: topup.subscription_id)
    
    if subscription.nil?
      Rails.logger.warn("Subscription not found for topup ID: #{topup.id}")
      return
    end
    
    # Koreksi: Perubahan variabel status menjadi result_code
    ActiveRecord::Base.transaction do
      begin
        if result_code == '00' # Sukses
          topup.update!(
            status: 'paid',
            paid_at: Time.current,
            # Set expiry date untuk topup (menggunakan ends_at dari subscription)
            expires_at: subscription.ends_at,
            duitku_transaction_id: notification['reference'],
            payment_details: notification
          )

          # Update subscription dengan nilai tambahan
          if topup.topup_type == 'max_active_users'
            # Tambahkan field additional_mau ke tabel subscriptions jika belum ada
            subscription.update!(additional_mau: (subscription.additional_mau || 0) + topup.amount.to_i)
            Rails.logger.info("Updated subscription #{subscription.id} with additional #{topup.amount} MAU")
          elsif topup.topup_type == 'ai_responses'
            # Tambahkan field additional_ai_response ke tabel subscriptions jika belum ada
            subscription.update!(additional_ai_responses: (subscription.additional_ai_responses || 0) + topup.amount.to_i)
            Rails.logger.info("Updated subscription #{subscription.id} with additional #{topup.amount} AI responses")
          end

          # Kirim notifikasi ke pengguna
          # AccountMailer.topup_successful(topup).deliver_later
        else
          topup.update!(
            status: 'failed',
            payment_details: notification
          )
          Rails.logger.info("Payment failed for topup: #{topup.id}, result code: #{result_code}")
        end
      rescue StandardError => e
        Rails.logger.error("Error processing topup webhook: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        raise ActiveRecord::Rollback
      end
    end
  end

  def update_subscription_payment(notification, result_code, merchant_order_id)
    # Find the subscription payment by duitku_order_id
    subscription_payment = SubscriptionPayment.find_by(duitku_order_id: merchant_order_id)
    
    if subscription_payment.nil?
      Rails.logger.warn("Payment not found for order ID: #{merchant_order_id}")
      return
    end
    
    # Find the related subscription
    subscription = Subscription.find_by(id: subscription_payment.subscription_id)
    
    if subscription.nil?
      Rails.logger.warn("Subscription not found for payment ID: #{subscription_payment.id}")
      return
    end
    
    Rails.logger.info("Found subscription: #{subscription.id}")
    
    ActiveRecord::Base.transaction do
      begin
        # Update subscription payment status based on resultCode
        if result_code == '00' # Success code from Duitku
          # Update the payment record we already found
          subscription_payment.update!(
            status: 'paid',
            paid_at: Time.current,
            duitku_transaction_id: notification['reference'],
            payment_details: notification
          )
          
          # Update subscription status
          subscription.update!(
            status: 'active',
            payment_status: 'paid'
          )

          # Update related transaction
          transaction = Transaction.find_by(transaction_id: merchant_order_id)
          if transaction.present?
            transaction.update!(
              status: 'paid',
              payment_date: Time.current,
              metadata: notification
            )
          else
            Rails.logger.warn("Transaction not found for transaction_id: #{merchant_order_id}")
          end

          # # End subscription Free Trial
          # subscription_free_trial = Subscription.find_by(account_id: subscription.account_id, plan_name: "Free Trial")
          # if subscription_free_trial.present?
          #   if subscription_free_trial.update(status: 'inactive')
          #     Rails.logger.info("Deactivated Free Trial subscription")
          #   else
          #     Rails.logger.error("Failed to deactivate: #{subscription_free_trial.errors.full_messages}")
          #   end
          # end
          
          # Update all active subscriptions for the account except the current one to inactive
          updated_count = Subscription.where(account_id: subscription.account_id, status: 'active', payment_status: 'paid')
          .where.not(id: subscription.id)
          .update_all(status: 'inactive')

          if updated_count > 0
            Rails.logger.info("Deactivated #{updated_count} previous active subscriptions for account #{subscription.account_id}")
          else
            Rails.logger.info("No previous active subscriptions found for account #{subscription.account_id}")
          end

          # Kirim email invoice
          if transaction.present?
            user = transaction.user
  
            InvoiceMailer.send_invoice(
              user.email,
              user.name,
              transaction.transaction_id,
              notification['settlementDate'],
              notification['amount'],
              notification['productDetail'],
            ).deliver_later
            Rails.logger.info("Payment confirmed & invoice sent to #{user.email} (##{transaction.transaction_id})")
          end
          
          Rails.logger.info("Updated subscription and payment to paid status")
        else
          subscription_payment.update!(
            status: 'failed',
            payment_details: notification
          )
          
          transaction = Transaction.find_by(transaction_id: merchant_order_id)
          transaction&.update!(
            status: 'failed',
            metadata: notification
          )
          
          Rails.logger.info("Payment not successful, result code: #{result_code}")
        end
      rescue StandardError => e
        Rails.logger.error("Error processing payment webhook: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        raise ActiveRecord::Rollback
      end
    end
  end

  def valid_signature?
    # Get the signature from the request parameters instead of headers
    received_signature = params['signature']
    merchant_code = params['merchantCode']
    amount = params['amount']
    merchant_order_id = params['merchantOrderId']
    
    # Make sure we have all required parameters
    return false if received_signature.blank? || merchant_code.blank? || amount.blank? || merchant_order_id.blank?
    
    # API key from environment
    api_key = ENV['DUITKU_API_KEY']
    
    # Calculate signature according to Duitku documentation
    # MD5(merchantCode + amount + merchantOrderId + apiKey)
    raw_signature = "#{merchant_code}#{amount}#{merchant_order_id}#{api_key}"
    computed_signature = Digest::MD5.hexdigest(raw_signature)
    
    Rails.logger.info("Validating signature: received=#{received_signature}, computed=#{computed_signature}")
    
    # Compare signatures
    received_signature == computed_signature
  end
    
  def payment_status_message(notification)
    status = notification['status']
    amount = notification['amount']
    payment_method = notification['paymentCode'] # Changed from paymentMethod to paymentCode
    
    case status
    when 'SUCCESS'
      "✅ Pembayaran sebesar Rp #{amount} melalui #{payment_method} telah berhasil."
    when 'PENDING'
      "⏳ Menunggu pembayaran sebesar Rp #{amount} melalui #{payment_method}."
    when 'CANCELED'
      "❌ Pembayaran sebesar Rp #{amount} melalui #{payment_method} telah dibatalkan."
    when 'FAILED'
      "❌ Pembayaran sebesar Rp #{amount} melalui #{payment_method} gagal."
    else
      "Status pembayaran: #{status}"
    end
  end
end