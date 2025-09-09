class Api::V1::SubscriptionsController < Api::BaseController
  # before_action :authenticate_user!
  # before_action :check_authorization
  # before_action :set_account
  # include AccessTokenAuthHelper
  # skip_before_action :authenticate_user!, only: [:index, :show]
  include AuthHelper
  include CacheKeysHelper

  # Skip authentication for the plans method
  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception, only: [:plans], raise: false
  skip_before_action :authenticate_access_token!, only: [:plans], raise: false
  skip_before_action :validate_bot_access_token!, only: [:plans], raise: false

  before_action :set_account, except: [:plans]
  before_action :set_subscription, only: [:show, :update, :cancel]
  before_action :set_subscription_plan, only: [:create]
  
  def index
    @subscriptions = @account.subscriptions.order(created_at: :desc)
    render json: @subscriptions
  end
  
  def show
    render json: @subscription.as_json(include: [:subscription_usage])
  end
  
  def create
    billing_cycle = params[:billing_cycle] || 'monthly'
    qty = params[:qty] || 1
    voucher_code = params[:voucher_code]
    price = calculate_package_price(@subscription_plan.monthly_price, @subscription_plan.name, qty)

    # Apply voucher if present
    if voucher_code.present?
      result = Voucher::VoucherPreview.new().preview(voucher_code, @account, @subscription_plan.id, price)
      if result[:voucher][:valid]
        voucher = result[:voucher][:voucher]
        price = result[:new_price]
      else
        render json: { success: false, error: result[:voucher][:error] }, status: :unprocessable_entity
      end
    end
    
    ActiveRecord::Base.transaction do
      @subscription = @account.subscriptions.new(
        plan_name: @subscription_plan.name,
        max_mau: @subscription_plan.max_mau,
        max_ai_agents: @subscription_plan.max_ai_agents,
        max_ai_responses: @subscription_plan.max_ai_responses,
        max_human_agents: @subscription_plan.max_human_agents,
        available_channels: @subscription_plan.available_channels,
        support_level: @subscription_plan.support_level,
        starts_at: Time.now,
        ends_at: Time.now + qty.month,
        billing_cycle: billing_cycle,
        price: price,
        subscription_plan_id: @subscription_plan.id # Optional reference
      )
      
      if @subscription.save
        VoucherUsage.create!(voucher: voucher, account: @account, subscription: @subscription) if voucher_code.present?
        
        begin
          order_id = "RADAI-#{@account.id}-#{@subscription.id}-#{Time.now.to_i}"

          transaction = Transaction.create!(
            transaction_id: order_id,
            user_id: current_user.id,
            account_id: @account.id,
            package_type: 'subscription',
            package_name: @subscription.plan_name,
            price: @subscription.price,
            duration: qty.to_i,
            duration_unit: 'month',
            status: 'pending',
            payment_method: params[:payment_method],
            transaction_date: Time.current,
            action: 'pay'
          )

          # Hubungkan subscription ke transaction
          TransactionSubscriptionRelation.create!(
            transaction_id: transaction.id,
            subscription_id: @subscription.id
          )

          payment_created = create_payment_for_subscription(order_id)
          payment = payment_created[:payment]

          transaction.update!(
            payment_url: payment.payment_url,
            expiry_date: payment.expires_at
          )  

          PaymentExpireJob.set(wait: (payment_created[:expiry_period].to_i + 1).minutes).perform_later(transaction.transaction_id)

          user = transaction.user
          InvoiceMailer.send_invoice_waiting(
              user.email,
              user.name,
              transaction.transaction_id,
              transaction.transaction_date.in_time_zone("Asia/Jakarta").strftime("%d-%m-%Y %H:%M:%S"),
              transaction.price.to_i,
              transaction.package_name,
              transaction.payment_method == 'M2' ? 'Virtual Account' : 'Credit Card',
            ).deliver_later
            Rails.logger.info("Payment confirmed & invoice sent to #{user.email} (##{transaction.transaction_id})")

          render json: { 
            subscription: @subscription, 
            subscription_payment: payment,
            transaction: transaction
          }, status: :created
        rescue => e
          Rails.logger.error "Payment creation error: #{e.message}"
          raise ActiveRecord::Rollback
          render json: { errors: "Failed to create payment: #{e.message}" }, status: :unprocessable_entity
        end
      else
        render json: { errors: @subscription.errors }, status: :unprocessable_entity
      end
    end
  end
  
  def update
    if @subscription.update(subscription_params)
      render json: @subscription
    else
      render json: { errors: @subscription.errors }, status: :unprocessable_entity
    end
  end
  
  def cancel
    @subscription.update(status: 'cancelled')
    render json: { message: 'Subscription cancelled successfully' }
  end
  
  def plans
    @plans = SubscriptionPlan
      .where(is_active: true)
      .where.not(name: 'Free Trial')
      .order(monthly_price: :asc)
    render json: @plans
  end
  
  def active
    @subscription_active = @account.subscriptions.includes(:subscription_usage).find_by(status: 'active')
    render json: @subscription_active.as_json(include: :subscription_usage)
  end
  
  def latest
    @subscription_active = @account.subscriptions.includes(:subscription_usage).find_by(status: 'active')
    unless @subscription_active
      @subscription_active = @account.subscriptions.includes(:subscription_usage).order(created_at: :desc).first
    end

    render json: @subscription_active.as_json(include: :subscription_usage)
  end
  
  def status
    subscription = @account.subscriptions.find_by(status: 'active')
    active = subscription&.active?
    render json: { active: active }
  end

  def histories
    @transactions = @account.transactions
      .includes(:subscriptions)
      .order(created_at: :desc)

    user_data = current_user.as_json(only: [:email, :name, :phone])

    transactions_json = @transactions.map do |transaction|
      transaction_data = transaction.as_json(include: {
        subscriptions: {
          only: [:id, :plan_name, :starts_at, :ends_at, :status]
        }
      })

      # Transformasi payment_method
      payment_label = case transaction.payment_method
                      when 'M2' then 'Virtual Account'
                      when 'CC', 'VC' then 'Credit Card'
                      else transaction.payment_method
                      end

      transaction_data.merge(
        payment_method: payment_label,
        user: user_data
      )
    end

    render json: transactions_json
  end
  
  private
  
  def round_price_by_range(amount)
    if amount < 1_000_000
      return (amount / 1_000.0).round * 1_000
    elsif amount < 2_000_000
      return (amount / 50_000.0).round * 50_000
    elsif amount < 5_000_000
      return (amount / 25_000.0).round * 25_000
    elsif amount < 6_000_000
      return (amount / 100_000.0).ceil * 100_000  # selalu naik
    elsif amount < 10_000_000
      return (amount / 100_000.0).round * 100_000
    elsif amount < 30_000_000
      return (amount / 250_000.0).round * 250_000
    else
      return (amount / 1_000_000.0).round * 1_000_000
    end
  end

  def calculate_package_price(price, plan_name, duration)
      # Hitung harga dasar sesuai durasi
      total = price * duration

      # Diskon berdasarkan durasi
      case duration
      when 3
        total = round_price_by_range(price * 3 * 0.98)  # diskon 2%
      when 6
        total = round_price_by_range(price * 6 * 0.95)  # diskon 5%
      when 12
        total = round_price_by_range(price * 12 * 0.90) # diskon 10%
      end

      # Bulatkan sesuai aturan range
      return total
  end
  
  def set_account
    @account = current_user.accounts.where(status: 'active').find(params[:account_id])
  end
  
  def set_subscription
    @subscription = @account.subscriptions.find(params[:id])
  end
  
  def set_subscription_plan
    @subscription_plan = SubscriptionPlan.find(params[:plan_id])
  end
  
  def subscription_params
    params.require(:subscription).permit(:billing_cycle)
  end
  
  def check_authorization
    authorize! :manage_subscription, @account
  end
  
  def create_payment_for_subscription(order_id)
    amount = @subscription.price.to_f.to_i
    
    payment_service = Duitku::PaymentService.new
    response = payment_service.create_payment(
      amount: amount,
      order_id: order_id,
      product_details: "#{@subscription.plan_name} Subscription (#{@subscription.billing_cycle})",
      customer_name: current_user.name,
      customer_email: current_user.email,
      return_url: "#{ENV['FRONTEND_URL']}/app/accounts/#{@account.id}/settings/billing",
      subscription_id: @subscription.id,
      payment_method: params[:payment_method]
    )

    Rails.logger.info "DOKU-PAYMENT: #{response.inspect}"
    Rails.logger.info "expiryPeriod: #{response[:expiryPeriod].inspect}"
    Rails.logger.info "expiryPeriod to_i: #{response[:expiryPeriod].to_i}"
    
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
      raise "Payment URL not present in response: #{response.inspect}"
    end
  end
end