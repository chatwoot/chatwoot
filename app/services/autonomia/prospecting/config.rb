module Autonomia::Prospecting::Config
  FEATURE_FLAG = 'autonomia_prospecting'.freeze

  def self.enabled?(account)
    account.present? && account.feature_enabled?(FEATURE_FLAG)
  end

  def self.enable_for!(account)
    account.enable_features!(FEATURE_FLAG)
    account
  end

  def self.disable_for!(account)
    account.disable_features!(FEATURE_FLAG)
    account
  end
end
