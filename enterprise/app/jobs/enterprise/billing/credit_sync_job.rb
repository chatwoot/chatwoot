class Enterprise::Billing::CreditSyncJob < ApplicationJob
  queue_as :low

  def perform(account = nil)
    if account
      sync_single_account(account)
    else
      sync_all_accounts
    end
  end

  private

  def sync_all_accounts
    Rails.logger.info '[CreditSyncJob] Starting credit sync for all accounts'

    accounts_with_stripe = Account.where("custom_attributes->>'stripe_customer_id' IS NOT NULL")
    synced_count = 0
    failed_count = 0

    accounts_with_stripe.find_each do |account|
      result = sync_account_credits(account)
      if result[:success]
        synced_count += 1 if result[:credits_reported].to_i.positive?
      else
        failed_count += 1
        Rails.logger.error "[CreditSyncJob] Failed to sync account #{account.id}: #{result[:message]}"
      end
    end

    Rails.logger.info "[CreditSyncJob] Completed. Synced: #{synced_count}, Failed: #{failed_count}"
    { synced: synced_count, failed: failed_count }
  end

  def sync_single_account(account)
    Rails.logger.info "[CreditSyncJob] Syncing credits for account #{account.id}"
    result = sync_account_credits(account)

    if result[:success]
      Rails.logger.info "[CreditSyncJob] Successfully synced account #{account.id}"
    else
      Rails.logger.error "[CreditSyncJob] Failed to sync account #{account.id}: #{result[:message]}"
    end

    result
  end

  def sync_account_credits(account)
    consumed_credits = account.custom_attributes&.[]('captain_responses_usage').to_i
    last_synced_credits = account.custom_attributes&.[]('stripe_last_synced_credits').to_i
    credits_to_report = consumed_credits - last_synced_credits

    if credits_to_report.positive?
      handle_positive_credits(account, credits_to_report, consumed_credits)
    elsif credits_to_report.negative?
      handle_negative_credits(account, credits_to_report, consumed_credits)
    else
      { success: true, message: 'Already in sync', credits_reported: 0 }
    end
  rescue StandardError => e
    handle_sync_error(account, e)
  end

  def handle_positive_credits(account, credits_to_report, consumed_credits)
    reporter = Enterprise::Billing::V2::UsageReporterService.new(account: account)
    result = reporter.report(credits_to_report)

    return result unless result[:success]

    update_last_synced_credits(account, consumed_credits)
    Rails.logger.info "[CreditSyncJob] Account #{account.id}: reported #{credits_to_report} credits (total: #{consumed_credits})"
    result.merge(credits_reported: credits_to_report)
  end

  def handle_negative_credits(account, credits_to_report, consumed_credits)
    Rails.logger.warn "[CreditSyncJob] Account #{account.id} has negative difference: #{credits_to_report}"
    update_last_synced_credits(account, consumed_credits)
    { success: true, message: 'Reset sync point due to negative difference', credits_reported: 0 }
  end

  def handle_sync_error(account, error)
    Rails.logger.error "[CreditSyncJob] Error syncing account #{account.id}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    { success: false, message: error.message }
  end

  def update_last_synced_credits(account, credits)
    account.with_lock do
      current_attributes = account.custom_attributes.present? ? account.custom_attributes.deep_dup : {}
      current_attributes['stripe_last_synced_credits'] = credits
      account.update!(custom_attributes: current_attributes)
    end
  end
end
