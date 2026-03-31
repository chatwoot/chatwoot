class Account::BrandingEnrichmentJob < ApplicationJob
  queue_as :low

  def perform(account_id, email)
    result = WebsiteBrandingService.new(email).perform
    return if result.blank?

    account = Account.find(account_id)
    update_account(account, result)
  ensure
    finish_enrichment(account_id)
  end

  private

  def update_account(account, data)
    set_account_name(account, data[:title])
    set_custom_attr(account, 'website', data[:domain])
    set_custom_attr(account, 'industry', data.dig(:industries, 0, :industry))
    set_social_handles(account, data[:socials])
    set_branding(account, data)
    set_custom_attr(account, 'brand_info', data)

    account.save! if account.changed?
  end

  def set_account_name(account, name)
    account.name = name if name.present?
  end

  def set_branding(account, data)
    branding = {}
    branding[:favicon] = data.dig(:logos, 0, :url) if data[:logos]&.any?
    branding[:primary_color] = data.dig(:colors, 0, :hex) if data[:colors]&.any?
    set_custom_attr(account, 'branding', branding) if branding.values.any?(&:present?)
  end

  def set_social_handles(account, socials)
    return if socials.blank?

    handles = socials.each_with_object({}) { |s, h| h[s[:type]] = s[:url] }
    set_custom_attr(account, 'social_handles', handles) if handles.values.any?(&:present?)
  end

  def set_custom_attr(account, key, value)
    return if value.blank?
    return if account.custom_attributes[key].present?

    account.custom_attributes[key] = value
  end

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
