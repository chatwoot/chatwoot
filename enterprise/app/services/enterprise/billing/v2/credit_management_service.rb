class Enterprise::Billing::V2::CreditManagementService < Enterprise::Billing::V2::BaseService
  def grant_monthly_credits(amount = 2000, metadata: {})
    result = with_locked_account do
      expired_amount = expire_current_monthly_credits(metadata: metadata)

      update_credits(monthly: amount)

      if amount.positive?
        log_credit_transaction(
          type: 'grant',
          amount: amount,
          credit_type: 'monthly',
          description: 'Monthly credit grant',
          metadata: base_metadata(metadata).merge('expired_amount' => expired_amount)
        )
      end

      { success: true, granted: amount, expired: expired_amount, remaining: total_credits }
    end

    Rails.logger.info "Granted #{amount} monthly credits to account #{account.id}"
    result
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to grant monthly credits to account #{account.id}: #{e.message}"
    { success: false, message: e.message }
  end

  # rubocop:disable Metrics/MethodLength
  def use_credit(feature: 'ai_captain', amount: 1, metadata: {})
    return { success: true, credits_used: 0, remaining: total_credits } if amount <= 0

    with_locked_account do
      return { success: false, message: 'Insufficient credits' } if total_credits < amount

      current_monthly = monthly_credits
      current_topup = topup_credits
      credit_type = 'monthly'

      if current_monthly >= amount
        update_credits(monthly: current_monthly - amount)
      else
        monthly_used = current_monthly
        topup_used = amount - monthly_used
        update_credits(monthly: 0, topup: current_topup - topup_used)
        credit_type = monthly_used.positive? ? 'mixed' : 'topup'
      end

      log_credit_transaction(
        type: 'use',
        amount: amount,
        credit_type: credit_type,
        description: "Used for #{feature}",
        metadata: base_metadata(metadata).merge('feature' => feature)
      )

      Enterprise::Billing::V2::UsageReporterService.new(account: account).report_async(amount, feature)

      { success: true, credits_used: amount, remaining: total_credits }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def add_topup_credits(amount, metadata: {})
    result = with_locked_account do
      new_balance = topup_credits + amount
      update_credits(topup: new_balance)

      log_credit_transaction(
        type: 'topup',
        amount: amount,
        credit_type: 'topup',
        description: 'Topup credits added',
        metadata: base_metadata(metadata)
      )

      { success: true, topup_balance: new_balance, total: total_credits }
    end

    Rails.logger.info "Added #{amount} topup credits to account #{account.id}"
    result
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to add topup credits to account #{account.id}: #{e.message}"
    { success: false, message: e.message }
  end

  def total_credits
    monthly_credits + topup_credits
  end

  def credit_balance
    {
      monthly: monthly_credits,
      topup: topup_credits,
      total: total_credits,
      last_synced: Time.current
    }
  end

  def expire_monthly_credits(metadata: {})
    with_locked_account do
      expired_amount = expire_current_monthly_credits(metadata: metadata)
      { success: true, expired: expired_amount, remaining: total_credits }
    end
  end

  private

  def expire_current_monthly_credits(metadata: {})
    current_monthly = monthly_credits
    return 0 if current_monthly.zero?

    update_credits(monthly: 0)

    log_credit_transaction(
      type: 'expire',
      amount: current_monthly,
      credit_type: 'monthly',
      description: 'Monthly credits expired',
      metadata: base_metadata(metadata)
    )

    current_monthly
  end

  def base_metadata(metadata)
    metadata.is_a?(Hash) ? metadata.stringify_keys : {}
  end
end
