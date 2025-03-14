class PricingPlan < ApplicationRecord
    validates :name, presence: true
    validates :price, :monthly_price, :annual_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :max_active_users, :human_agents, :ai_agents, :ai_responses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    
    serialize :integration_channels, Array # Menyimpan array channel (Livechat, WhatsApp, Telegram)
  end
  