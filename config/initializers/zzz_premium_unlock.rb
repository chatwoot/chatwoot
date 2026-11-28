# frozen_string_literal: true

# Unlock de recursos Enterprise para instância self-hosted.
# Arquivo aditivo: reaplicado automaticamente em toda release.
# Ver PREMIUM.md.

module PremiumUnlock
  RISKY = %w[
    advanced_search
    advanced_search_indexing
    company_enrichment
  ].freeze

  def self.forced_features
    @forced_features ||= begin
      list = Featurable::FEATURE_LIST.select { |f| f['premium'] }.pluck('name') - RISKY
      ENV['PREMIUM_UNLOCK_ALL'] == '1' ? (list + RISKY).uniq : list
    end
  end

  def self.force_plan!
    return if ENV['PREMIUM_UNLOCK_DISABLE'] == '1'
    return unless ActiveRecord::Base.connection.data_source_exists?('installation_configs')

    {
      'INSTALLATION_PRICING_PLAN' => 'enterprise',
      'INSTALLATION_PRICING_PLAN_QUANTITY' => ChatwootApp.max_limit.to_s,
      'INSTALLATION_SUBSCRIPTION_STATUS' => 'active'
    }.each do |name, value|
      config = InstallationConfig.find_or_initialize_by(name: name)
      next if config.value.to_s == value

      config.value = value
      config.save(validate: false)
    end

    GlobalConfig.clear_cache if defined?(GlobalConfig) && GlobalConfig.respond_to?(:clear_cache)
  rescue StandardError => e
    Rails.logger.warn("[premium_unlock] plano não forçado: #{e.class}: #{e.message}")
  end

  def self.enable_features_on_accounts!
    return if ENV['PREMIUM_UNLOCK_DISABLE'] == '1'
    return unless ActiveRecord::Base.connection.data_source_exists?('accounts')

    Account.find_each do |account|
      account.enable_features!(*forced_features)
    rescue StandardError => e
      Rails.logger.warn("[premium_unlock] conta #{account.id}: #{e.message}")
    end
  rescue StandardError => e
    Rails.logger.warn("[premium_unlock] features não habilitadas: #{e.class}: #{e.message}")
  end

  module ChatwootHubOverride
    def pricing_plan = 'enterprise'
    def pricing_plan_quantity = ChatwootApp.max_limit
    def subscription_status = 'active'
  end

  module ChatwootAppOverride
    def self_hosted_paid? = true
    def self_hosted_enterprise? = true
  end

  module AccountOverride
    def feature_enabled?(name)
      return true if PremiumUnlock.forced_features.include?(name.to_s)

      super
    end

    def subscribed_features
      PremiumUnlock.forced_features
    end
  end

  module CheckNewVersionsJobOverride
    def perform(*args)
      super
    ensure
      PremiumUnlock.force_plan!
    end
  end
end

Rails.application.config.after_initialize do
  next if ENV['PREMIUM_UNLOCK_DISABLE'] == '1'

  ChatwootHub.singleton_class.prepend(PremiumUnlock::ChatwootHubOverride)
  ChatwootApp.singleton_class.prepend(PremiumUnlock::ChatwootAppOverride)
  Account.prepend(PremiumUnlock::AccountOverride)
  Internal::CheckNewVersionsJob.prepend(PremiumUnlock::CheckNewVersionsJobOverride)

  PremiumUnlock.force_plan!
  PremiumUnlock.enable_features_on_accounts!
end