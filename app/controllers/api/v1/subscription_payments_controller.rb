class Api::V1::SubscriptionPaymentsController < Api::BaseController
  include AuthHelper
  include CacheKeysHelper
  
  skip_before_action :authenticate_user!, only: [:webhook]
  #skip_before_action :authenticate_access_token, only: [:webhook]
  before_action :authenticate_user!, except: [:webhook]
  before_action :set_account, except: [:webhook]
  before_action :set_subscription, except: [:webhook]

    def index
      @payments = @subscription.subscription_payments.order(created_at: :desc)
      render json: @payments
    end
    
    def create
      # Create new payment for existing subscription
      order_id = "PAY-#{@account.id}-#{@subscription.id}-#{Time.now.to_i}"
      amount = @subscription.price
      
      payment_service = Duitku::PaymentService.new
      response = payment_service.create_payment(
        amount: amount,
        order_id: order_id,
        product_details: "#{@subscription.plan_name} Subscription (#{@subscription.billing_cycle})",
        customer_name: current_user.name,
        customer_email: current_user.email,
        return_url: "#{ENV['CHATWOOT_FRONTEND_URL']}/app/accounts/#{@account.id}/settings/subscriptions",
        subscription_id: @subscription.id
      )
      
      if response['paymentUrl'].present?
        @payment = @subscription.subscription_payments.create!(
          amount: amount,
          duitku_order_id: order_id,
          payment_url: response['paymentUrl'],
          payment_method: 'DUITKU',
          expires_at: Time.now + 1.hour
        )
        render json: @payment, status: :created
      else
        render json: { error: 'Failed to create payment URL' }, status: :unprocessable_entity
      end
    end
    
    def show
      @payment = @subscription.subscription_payments.find(params[:id])
      render json: @payment
    end
    
    def check_status
      @payment = @subscription.subscription_payments.find(params[:id])
      
      payment_service = Duitku::PaymentService.new
      response = payment_service.check_transaction(@payment.duitku_order_id)
      
      if response['statusCode'] == '00'
        # Payment successful
        @payment.update(
          status: 'paid',
          payment_method: response['channelId'],
          paid_at: Time.now,
          payment_details: response
        )
        
        # Update subscription
        @subscription.update(
          status: 'active',
          payment_status: 'paid',
          amount_paid: @payment.amount
        )
        
        # Set as active subscription for the account
        @account.update(
          active_subscription_id: @subscription.id,
          subscription_status: 'active'
        )
      end
      
      render json: {
        payment: @payment,
        duitku_status: response
      }
    end
    
    def webhook
      # Validate signature
      valid_signature = validate_duitku_signature(params)
      
      unless valid_signature
        render json: { error: 'Invalid signature' }, status: :unauthorized
        return
      end
      
      # Find payment by order ID
      order_id = params[:merchantOrderId]
      @payment = SubscriptionPayment.find_by(duitku_order_id: order_id)
      
      if @payment.blank?
        render json: { error: 'Payment not found' }, status: :not_found
        return
      end
      
      @subscription = @payment.subscription
      
      # Process payment based on result code
      if params[:resultCode] == '00' || params[:resultCode] == 'Success'
        # Payment successful
        @payment.update(
          status: 'paid',
          payment_method: params[:paymentCode],
          paid_at: Time.now,
          payment_details: params.as_json
        )
        
        # Update subscription
        @subscription.update(
          status: 'active',
          payment_status: 'paid',
          amount_paid: @payment.amount
        )
        
        # Set as active subscription for the account
        @subscription.account.update(
          active_subscription_id: @subscription.id,
          subscription_status: 'active'
        )
        
        # Initialize or reset usage records
        SubscriptionUsage.find_or_create_by(subscription_id: @subscription.id).update(
          last_reset_at: Time.now
        )
      else
        # Payment failed
        @payment.update(
          status: 'failed',
          payment_details: params.as_json
        )
      end
      
      render json: { success: true }, status: :ok
    end
    
    private
    
    def set_account
      @account = current_user.accounts.find(params[:account_id])
    end
    
    def set_subscription
      @subscription = @account.subscriptions.find(params[:subscription_id])
    end
    
    def validate_duitku_signature(params)
      merchant_code = params[:merchantCode]
      order_id = params[:merchantOrderId]
      amount = params[:amount]
      result_code = params[:resultCode]
      reference = params[:reference]
      signature = params[:signature]
      
      api_key = ENV['DUITKU_API_KEY']
      
      computed_signature = Digest::MD5.hexdigest(merchant_code + order_id + amount + result_code + reference + api_key)
      
      signature == computed_signature
    end
end