module Autonomia::Prospecting::Config
  BOOLEAN = ActiveModel::Type::Boolean.new
  INTERNAL_ATTR_KEY = 'autonomia_prospecting_enabled'.freeze

  def self.enabled?(account)
    BOOLEAN.cast(account&.internal_attributes&.[](INTERNAL_ATTR_KEY)) || false
  end

  def self.enable_for!(account)
    account.internal_attributes[INTERNAL_ATTR_KEY] = true
    account.save!
    account
  end

  def self.disable_for!(account)
    account.internal_attributes[INTERNAL_ATTR_KEY] = false
    account.save!
    account
  end
end
