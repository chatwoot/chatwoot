module Autonomia::Prospecting::Config
  BOOLEAN = ActiveModel::Type::Boolean.new
  INTERNAL_ATTR_KEY = 'autonomia_prospecting_enabled'.freeze

  def self.enabled?(account)
    BOOLEAN.cast(account&.internal_attributes&.[](INTERNAL_ATTR_KEY)) || false
  end

  def self.enable_for!(account)
    update_internal_attribute!(account, true)
    account
  end

  def self.disable_for!(account)
    update_internal_attribute!(account, false)
    account
  end

  def self.update_internal_attribute!(account, enabled)
    account.internal_attributes = account.internal_attributes.to_h.merge(INTERNAL_ATTR_KEY => enabled)
    account.save!
  end
end
