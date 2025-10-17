class Enterprise::Billing::V2::CreditManagementService < Enterprise::Billing::V2::BaseService
  def use_credit(feature: 'ai_captain', amount: 1, metadata: {})
    return { success: true, credits_used: 0, remaining: total_credits } if amount <= 0

    with_locked_account do
      return { success: false, message: 'Insufficient credits' } unless total_credits >= amount

      # Report usage to Stripe
      stripe_result = report_usage_to_stripe(amount, feature)
      return { success: false, message: stripe_result[:message] } unless stripe_result[:success]

      # Deduct credits locally (monthly first, then topup)
      deduct_credits(amount)

      # Log transaction
      log_credit_transaction(
        type: 'use',
        amount: amount,
        credit_type: determine_credit_type(amount),
        description: "Used for #{feature}",
        metadata: metadata
      )

      { success: true, credits_used: amount, remaining: total_credits }
    end
  end

  def sync_monthly_credits(amount)
    with_locked_account do
      update_credits(monthly: amount)
      if amount.positive?
        log_credit_transaction(
          type: 'grant',
          amount: amount,
          credit_type: 'monthly',
          description: 'Monthly credits from Stripe'
        )
      end
    end
  end

  def add_topup_credits(amount)
    with_locked_account do
      update_credits(topup: topup_credits + amount)
      log_credit_transaction(
        type: 'topup',
        amount: amount,
        credit_type: 'topup',
        description: 'Topup credits added'
      )
    end
  end

  def expire_monthly_credits
    with_locked_account do
      expired = monthly_credits
      update_credits(monthly: 0) if expired.positive?
      expired
    end
  end

  def credit_balance
    {
      monthly: monthly_credits,
      topup: topup_credits,
      total: total_credits
    }
  end

  def total_credits
    monthly_credits + topup_credits
  end

  private

  def report_usage_to_stripe(amount, feature)
    Enterprise::Billing::V2::UsageReporterService.new(account: account).report(amount, feature)
  end

  def deduct_credits(amount)
    if monthly_credits >= amount
      update_credits(monthly: monthly_credits - amount)
    else
      remaining = amount - monthly_credits
      update_credits(monthly: 0, topup: topup_credits - remaining)
    end
  end

  def determine_credit_type(amount)
    if monthly_credits >= amount
      'monthly'
    elsif monthly_credits.positive?
      'mixed'
    else
      'topup'
    end
  end
end
