class Enterprise::Billing::V2::CreditManagementService < Enterprise::Billing::V2::BaseService
  def fetch_stripe_credit_balance
    sync_service.fetch_stripe_credit_balance
  end

  def create_stripe_credit_grant(amount, type: 'promotional', metadata: {})
    sync_service.create_stripe_credit_grant(amount, type: type, metadata: metadata)
  end

  def grant_monthly_credits(amount = 2000, metadata: {})
    with_locked_account do
      expired_amount = expire_current_monthly_credits(metadata: metadata)
      stripe_grant = create_stripe_credit_grant(amount, type: 'monthly', metadata: metadata)
      update_credits(monthly: amount)
      log_monthly_grant(amount, expired_amount, stripe_grant&.id, metadata) if amount.positive?
      { success: true, granted: amount, expired: expired_amount, remaining: total_credits }
    end
  end

  def use_credit(feature: 'ai_captain', amount: 1, metadata: {})
    return { success: true, credits_used: 0, remaining: total_credits } if amount <= 0

    with_locked_account do
      return { success: false, message: 'Insufficient credits' } unless sufficient_balance?(amount)

      stripe_result = report_usage_to_stripe(amount, feature, metadata)
      return { success: false, message: "Usage reporting failed: #{stripe_result[:message]}" } unless stripe_result[:success]

      credit_type = deduct_credits(amount)
      log_credit_usage(amount, feature, credit_type, stripe_result[:event_id], metadata)
      build_credit_usage_result(amount, stripe_result[:event_id])
    end
  end

  def add_topup_credits(amount, metadata: {})
    with_locked_account do
      stripe_grant = create_stripe_credit_grant(amount, type: 'topup', metadata: metadata)
      new_balance = topup_credits + amount
      update_credits(topup: new_balance)
      log_credit_transaction(
        type: 'topup', amount: amount, credit_type: 'topup',
        description: 'Topup credits added',
        metadata: base_metadata(metadata).merge('stripe_grant_id' => stripe_grant&.id)
      )
      { success: true, topup_balance: new_balance, total: total_credits }
    end
  end

  def total_credits
    monthly_credits + topup_credits
  end

  def credit_balance
    stripe_usage = sync_service.fetch_stripe_usage_total
    initial_credits = initial_credits_from_local
    if stripe_usage.is_a?(Numeric) && initial_credits
      balance = sync_service.calculate_balance_from_stripe(stripe_usage, initial_credits)
      sync_local_balance_from_stripe(balance)
      balance
    else
      sync_service.local_fallback_balance
    end
  end

  def expire_monthly_credits(metadata: {})
    with_locked_account do
      expired_amount = expire_current_monthly_credits(metadata: metadata)
      { success: true, expired: expired_amount, remaining: total_credits }
    end
  end

  private

  def sync_service
    @sync_service ||= Enterprise::Billing::V2::StripeCreditSyncService.new(account: account)
  end

  def initial_credits_from_local
    monthly_granted = account.credit_transactions.where(transaction_type: 'grant', credit_type: 'monthly').sum(:amount)
    topup_granted = account.credit_transactions.where(transaction_type: 'topup').sum(:amount)
    { monthly_granted: monthly_granted, topup_granted: topup_granted, total_granted: monthly_granted + topup_granted }
  end

  def expire_current_monthly_credits(metadata: {})
    current_monthly = monthly_credits
    return 0 if current_monthly.zero?

    update_credits(monthly: 0)
    log_credit_transaction(
      type: 'expire', amount: current_monthly, credit_type: 'monthly',
      description: 'Monthly credits expired', metadata: base_metadata(metadata)
    )
    current_monthly
  end

  def base_metadata(metadata)
    metadata.is_a?(Hash) ? metadata.stringify_keys : {}
  end

  def log_monthly_grant(amount, expired_amount, grant_id, metadata)
    log_credit_transaction(
      type: 'grant',
      amount: amount,
      credit_type: 'monthly',
      description: 'Monthly credit grant',
      metadata: base_metadata(metadata).merge('expired_amount' => expired_amount, 'stripe_grant_id' => grant_id)
    )
  end

  def report_usage_to_stripe(amount, feature, metadata)
    reporter = Enterprise::Billing::V2::UsageReporterService.new(account: account)
    reporter.report(amount, feature, metadata)
  end

  def sufficient_balance?(amount)
    # Use local balance (real-time) instead of Stripe balance (5-10 min delay)
    total_credits >= amount
  end

  def deduct_credits(amount)
    current_monthly = monthly_credits
    current_topup = topup_credits

    if current_monthly >= amount
      update_credits(monthly: current_monthly - amount)
      'monthly'
    else
      monthly_used = current_monthly
      topup_used = amount - monthly_used
      update_credits(monthly: 0, topup: current_topup - topup_used)
      monthly_used.positive? ? 'mixed' : 'topup'
    end
  end

  def log_credit_usage(amount, feature, credit_type, event_id, metadata)
    log_credit_transaction(
      type: 'use',
      amount: amount,
      credit_type: credit_type,
      description: "Used for #{feature}",
      metadata: base_metadata(metadata).merge('feature' => feature, 'stripe_event_id' => event_id)
    )
  end

  def build_credit_usage_result(amount, event_id)
    # Use local balance (already deducted) instead of fetching from Stripe
    {
      success: true,
      credits_used: amount,
      remaining: total_credits,
      source: 'local',
      stripe_event_id: event_id
    }
  end

  def sync_local_balance_from_stripe(stripe_balance)
    update_credits(
      monthly: stripe_balance[:monthly],
      topup: stripe_balance[:topup]
    )
  end
end
