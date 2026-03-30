class Account::BrandingEnrichmentJob < ApplicationJob
  queue_as :low

  def perform(account_id, email)
    Account::SignUpEmailValidationService.new(email).perform

    domain = email.split('@').last&.downcase
    result = WebsiteBrandingService.new(domain).perform
    return if result.blank?

    account = Account.find(account_id)
    update_account(account, result)
  rescue CustomExceptions::Account::InvalidEmail
    # Skip enrichment for invalid/disposable/blocked emails
    nil
  ensure
    finish_enrichment(account_id)
  end

  private

  def update_account(account, data)
    set_account_name(account, data[:business_name])
    set_account_locale(account, data[:language])
    set_custom_attr(account, 'website', data[:website])
    set_custom_attr(account, 'industry', data[:industry_category])
    set_custom_attr(account, 'social_handles', data[:social_handles]) if data[:social_handles]&.values&.any?(&:present?)
    set_branding(account, data)

    account.save! if account.changed?
  end

  def set_account_name(account, name)
    account.name = name if name.present?
  end

  def set_account_locale(account, language)
    return if language.blank? || account.locale != 'en'

    account.locale = language if LANGUAGES_CONFIG.any? { |_k, v| v[:iso_639_1_code] == language }
  end

  def set_branding(account, data)
    branding = {}
    branding[:website] = data[:website] if data[:website].present?
    branding.merge!(data[:branding]) if data[:branding]&.values&.any?(&:present?)
    set_custom_attr(account, 'branding', branding) if branding.present?
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
