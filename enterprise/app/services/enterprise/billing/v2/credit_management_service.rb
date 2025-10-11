class Enterprise::Billing::V2::CreditManagementService < Enterprise::Billing::V2::BaseService
  # Core method: Use credits and report to Stripe
  def use_credit(feature: 'ai_captain', amount: 1)
    return { success: true, credits_used: 0, remaining: total_credits } if amount <= 0

    with_locked_account do
      return { success: false, message: 'Insufficient credits' } unless total_credits >= amount

      # Report usage to Stripe for billing
      stripe_result = report_usage_to_stripe(amount, feature)
      return { success: false, message: "Usage reporting failed: #{stripe_result[:message]}" } unless stripe_result[:success]

      # Deduct credits locally
      deduct_credits(amount)

      # Log the transaction
      log_credit_transaction(
        type: 'use',
        amount: amount,
        credit_type: determine_credit_type(amount),
        description: "Used for #{feature}"
      )

      { success: true, credits_used: amount, remaining: total_credits }
    end
  end

  # Webhook handlers - just sync what Stripe tells us
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

  def sync_monthly_expired
    with_locked_account do
      expired = monthly_credits
      update_credits(monthly: 0) if expired.positive?
      expired
    end
  end

  def add_topup_credits(amount)
    with_locked_account do
      new_balance = topup_credits + amount
      update_credits(topup: new_balance)
      log_credit_transaction(
        type: 'topup',
        amount: amount,
        credit_type: 'topup',
        description: 'Topup credits added'
      )
    end
  end

  def total_credits
    monthly_credits + topup_credits
  end

  private

  def report_usage_to_stripe(amount, feature)
    reporter = Enterprise::Billing::V2::UsageReporterService.new(account: account)
    reporter.report(amount, feature)
  end

  def deduct_credits(amount)
    current_monthly = monthly_credits
    current_topup = topup_credits

    if current_monthly >= amount
      update_credits(monthly: current_monthly - amount)
    else
      monthly_used = current_monthly
      topup_used = amount - monthly_used
      update_credits(monthly: 0, topup: current_topup - topup_used)
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
