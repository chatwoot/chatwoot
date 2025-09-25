class AppleMessagesForBusiness::PaymentGatewayController < ApplicationController
  before_action :find_channel
  protect_from_forgery except: [:process_payment, :payment_method_update, :webhook]

  def process_payment
    payment_token = params[:paymentToken]
    payment_data = params[:paymentData]

    return render_error('Missing payment token') unless payment_token
    return render_error('Missing payment data') unless payment_data

    apple_pay_service = AppleMessagesForBusiness::ApplePayService.new(@channel)

    begin
      result = apple_pay_service.process_payment_authorization(payment_token, payment_data)

      if result[:success]
        render json: {
          success: true,
          transaction_id: result[:transaction_id],
          status: result[:status],
          amount: result[:amount],
          currency: result[:currency]
        }
      else
        render json: { error: result[:error], status: result[:status] }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "Apple Pay payment processing error: #{e.message}"
      render json: { error: 'Payment processing failed' }, status: :internal_server_error
    end
  end

  def payment_method_update
    update_type = params[:type]
    update_data = params[:data]

    return render_error('Missing update type') unless update_type
    return render_error('Missing update data') unless update_data

    apple_pay_service = AppleMessagesForBusiness::ApplePayService.new(@channel)

    begin
      result = apple_pay_service.handle_payment_method_update({
        type: update_type,
        **update_data.symbolize_keys
      })

      if result[:error]
        render json: { error: result[:error] }, status: :unprocessable_entity
      else
        render json: result
      end
    rescue StandardError => e
      Rails.logger.error "Apple Pay method update error: #{e.message}"
      render json: { error: 'Update processing failed' }, status: :internal_server_error
    end
  end

  def create_merchant_session
    merchant_session_service = AppleMessagesForBusiness::MerchantSessionService.new(@channel)

    result = merchant_session_service.create_session

    if result[:success]
      render json: {
        merchantSession: result[:session_data],
        expiresAt: result[:expires_at],
        merchantIdentifier: result[:merchant_identifier]
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def validate_merchant_session
    session_id = params[:sessionId]

    return render_error('Missing session ID') unless session_id

    merchant_session_service = AppleMessagesForBusiness::MerchantSessionService.new(@channel)
    result = merchant_session_service.validate_session(session_id)

    if result[:valid]
      render json: { valid: true, session: result[:session] }
    else
      render json: { valid: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  def webhook
    gateway_type = params[:gateway] || detect_gateway_from_headers
    webhook_data = {
      payload: request.body.read,
      signature: extract_webhook_signature,
      headers: request.headers
    }

    gateway_service = AppleMessagesForBusiness::PaymentGatewayService.new(@channel)
    result = gateway_service.handle_webhook(webhook_data, gateway_type)

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: { status: 'processed' }
    end
  rescue StandardError => e
    Rails.logger.error "Payment webhook processing error: #{e.message}"
    render json: { error: 'Webhook processing failed' }, status: :internal_server_error
  end

  def payment_status
    transaction_id = params[:transactionId]
    gateway_type = params[:gateway] || 'stripe'

    return render_error('Missing transaction ID') unless transaction_id

    gateway_service = AppleMessagesForBusiness::PaymentGatewayService.new(@channel)
    result = gateway_service.validate_transaction(transaction_id, gateway_type)

    if result[:valid]
      render json: {
        valid: true,
        status: result[:status],
        amount: result[:amount],
        currency: result[:currency],
        created: result[:created]
      }
    else
      render json: { valid: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def find_channel
    @channel = Channel::AppleMessagesForBusiness.find_by!(msp_id: params[:msp_id])
  rescue ActiveRecord::RecordNotFound
    render_error('Channel not found')
  end

  def render_error(error_message)
    render json: { error: error_message }, status: :unprocessable_entity
  end

  def detect_gateway_from_headers
    if request.headers['Stripe-Signature']
      'stripe'
    elsif request.headers['X-Square-Signature']
      'square'
    elsif request.headers['Bt-Signature']
      'braintree'
    else
      'unknown'
    end
  end

  def extract_webhook_signature
    request.headers['Stripe-Signature'] ||
    request.headers['X-Square-Signature'] ||
    request.headers['Bt-Signature'] ||
    request.headers['HTTP_X_HUB_SIGNATURE_256']
  end
end