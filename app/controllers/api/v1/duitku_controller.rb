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
    
    # Log the notification for debugging
    Rails.logger.info("Processing Duitku webhook: #{notification.inspect}")
    
    # Find the subscription payment by duitku_order_id
    subscription_payment = SubscriptionPayment.find_by(duitku_order_id: merchant_order_id)
    
    if subscription_payment.nil?
      Rails.logger.warn("Payment not found for order ID: #{merchant_order_id}")
      render json: { success: false, message: "Payment not found" }, status: :not_found
      return
    end
    
    # Find the related subscription
    subscription = Subscription.find_by(id: subscription_payment.subscription_id)
    
    if subscription.nil?
      Rails.logger.warn("Subscription not found for payment ID: #{subscription_payment.id}")
      render json: { success: false, message: "Subscription not found" }, status: :not_found
      return
    end
    
    Rails.logger.info("Found subscription: #{subscription.id}")
    
    # Update subscription payment status based on resultCode
    if result_code == '00' # Success code from Duitku
      # Update the payment record we already found
      subscription_payment.update(
        status: 'paid',
        paid_at: Time.current,
        duitku_transaction_id: notification['reference'],
        payment_details: notification
      )
      
      # Update subscription status
      subscription.update(
        status: 'active',
        payment_status: 'paid'
      )

      # End subscription Free Trial
      subscription_free_trial = Subscription.find_by(account_id: subscription.account_id, plan_name: "Free Trial")
      if subscription_free_trial.present?
        if subscription_free_trial.update(status: 'inactive')
          Rails.logger.info("Deactivated Free Trial subscription")
        else
          Rails.logger.error("Failed to deactivate: #{subscription_free_trial.errors.full_messages}")
        end
      end
      
      Rails.logger.info("Updated subscription and payment to paid status")
    else
      Rails.logger.info("Payment not successful, result code: #{result_code}")
    end

    render json: { success: true }
  end

  private

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