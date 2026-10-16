class Account::BrandingEnrichmentJob < ApplicationJob
  queue_as :low

  def perform(account_id, email)
    result = WebsiteBrandingService.new(email).perform
    if result.blank?
      Rails.logger.info "[BrandingEnrichment] Enrichment failed for account=#{account_id} email=#{email}"
      return
    end

    account = Account.find(account_id)
    account.name = result[:title] if result[:title].present?
    account.custom_attributes['brand_info'] = result if account.custom_attributes['brand_info'].blank?
    account.save! if account.changed?
  ensure
    finish_enrichment(account_id)
  end

  private

  def finish_enrichment(account_id)
    Redis::Alfred.delete(format(Redis::Alfred::ACCOUNT_ONBOARDING_ENRICHMENT, account_id: account_id))

    account = Account.find(account_id)
    if account.custom_attributes['onboarding_step'] == 'enrichment'
      account.custom_attributes['onboarding_step'] = 'account_details'
      account.save!
    end

    user = account.administrators.first
    return unless user

    ActionCableBroadcastJob.perform_later([user.pubsub_token], 'account.enrichment_completed', { account_id: account_id })
  end
end
