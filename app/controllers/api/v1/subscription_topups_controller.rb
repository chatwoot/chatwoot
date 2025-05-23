class Api::V1::SubscriptionTopupsController < Api::BaseController
  include AuthHelper
  include CacheKeysHelper

  before_action :set_account
  before_action :set_subscription, only: [:create]

  def create
    ActiveRecord::Base.transaction do
      begin
        @topup = @subscription.subscription_topups.new(topup_params)
        
        # Set harga berdasarkan jenis dan jumlah topup
        @topup.price = calculate_price(@topup.topup_type, @topup.amount)
        @topup.status = 'pending'
        
        if @topup.save
          # Buat pembayaran melalui Duitku
          payment_created = create_duitku_payment(@topup)
          payment = payment_created[:payment]
          
          if payment.present? && payment.payment_url.present?
            @topup.update!(
              duitku_order_id: payment.duitku_order_id,
              payment_url: payment.payment_url,
              status: 'pending',
              duitku_transaction_id: payment.duitku_transaction_id,
              payment_method: payment.payment_method,
              expires_at: payment.expires_at
            )

            transaction = create_transaction(payment)

            PaymentExpireJob.set(wait: (payment_created[:expiry_period].to_i + 2).minutes).perform_later(transaction.transaction_id)

            user = transaction.user
            invoice_prefix = payment.duitku_order_id.split('-')[1]

            case invoice_prefix
            when 'MAU'
              InvoiceMailer.mau_send_invoice_waiting(
                user.email,
                user.name,
                transaction.transaction_id,
                transaction.payment_date,
                transaction.price.to_i,
                transaction.package_name,
                transaction.payment_method == 'M2' ? 'Virtual Account' : 'Credit Card',
                @topup.amount.to_i, 
                transaction.expiry_date
              ).deliver_later
              Rails.logger.info("Payment waiting & invoice sent to #{user.email} (##{transaction.transaction_id})")
            when 'AR'
              InvoiceMailer.ai_send_invoice_waiting(
                user.email,
                user.name,
                transaction.transaction_id,
                transaction.payment_date,
                transaction.price.to_i,
                transaction.package_name,
                transaction.payment_method == 'M2' ? 'Virtual Account' : 'Credit Card',
                @topup.amount.to_i,
                transaction.expiry_date
              ).deliver_later
              Rails.logger.info("Payment waiting & invoice sent to #{user.email} (##{transaction.transaction_id})")
            end
            
            render json: { 
              topup: @topup, 
              payment_url: @topup.payment_url,
              transaction: transaction 
            }
          else
            raise StandardError, "Payment creation failed"
          end
        else
          raise StandardError, @topup.errors.full_messages.join(', ')
        end
      rescue StandardError => e
        @topup.update(status: 'failed') if @topup&.persisted?
        Rails.logger.error "Topup creation failed: #{e.message}"
        render json: { error: e.message }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end
  
  def index
    @subscription = @account.subscriptions.find_by(status: 'active')
    @topups = @subscription.subscription_topups.order(created_at: :desc)
    render json: @topups
  end
  
  private
  
  def set_account
    @account = current_user.accounts.find_by(status: 'active')
    render json: { error: 'Active account not found' }, status: :not_found unless @account
  end
  
  def set_subscription
    @subscription = @account.subscriptions.find(params[:subscription_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Subscription not found' }, status: :not_found
  end
  
  def topup_params
    params.require(:topup).permit(:topup_type, :amount)
  end
  
  def calculate_price(type, amount)
    block_size = 1000
  
    case type
    when 'max_active_users'
      block_price = 150_000
    when 'ai_responses'
      block_size = 5000
      block_price = 200_000
    else
      return 0
    end
  
    blocks = (amount.to_f / block_size).ceil
    blocks * block_price
  end
  
  def create_duitku_payment(topup)
    invoice_prefix = topup.topup_type.split('_').map { |word| word[0].upcase }.join
    order_id = "RADAI-#{invoice_prefix}-#{@account.id}-#{@subscription.id}-#{Time.now.to_i}"
    amount = topup.price.to_f.to_i
    
    payment_service = Duitku::PaymentService.new
    response = payment_service.create_payment(
      amount: amount,
      order_id: order_id,
      product_details: "TOPUP #{topup.topup_type} #{@subscription.plan_name} Subscription (#{@subscription.billing_cycle})",
      customer_name: current_user.name,
      customer_email: current_user.email,
      return_url: "#{ENV['DUITKU_CALLBACK_URL']}/app/accounts/#{@account.id}/settings/subscriptions",
      subscription_id: @subscription.id,
      payment_method: params[:payment_method]
    )

    Rails.logger.info "DOKU-PAYMENT: #{response.inspect}"
    
    if response['paymentUrl'].present?
      payment = @subscription.subscription_payments.create!(
        amount: amount,
        duitku_order_id: order_id,
        payment_url: response['paymentUrl'],
        payment_method: params[:payment_method],
        expires_at: Time.current + response[:expiryPeriod].to_i.minutes
      )
      return {
        payment: payment,
        expiry_period: response[:expiryPeriod]
      }
    else
      raise StandardError, "Payment URL not present in response: #{response.inspect}"
    end
  end

  def create_transaction(payment)
    # Create the transaction record
    transaction = Transaction.create!(
      transaction_id: payment.duitku_order_id,
      user_id: current_user.id,
      account_id: @account.id,
      package_type: 'topup',
      package_name: "#{@subscription.plan_name}_Credit_Topup_#{@topup.topup_type}",
      price: payment.amount.to_f.to_i,
      duration: 1,
      duration_unit: 'one_time',
      status: 'pending',
      payment_method: params[:payment_method],
      transaction_date: Time.current,
      action: 'pay',
      payment_url: payment.payment_url,
      expiry_date: payment.expires_at
    )

    return transaction;
  end
end