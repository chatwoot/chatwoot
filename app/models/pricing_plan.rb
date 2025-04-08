# == Schema Information
#
# Table name: pricing_plans
#
#  id                   :bigint           not null, primary key
#  ai_agents            :integer          default(0)
#  ai_responses         :integer
#  annual_price         :integer          default(0)
#  dedicated_support    :boolean          default(FALSE)
#  description          :text
#  human_agents         :integer
#  integration_channels :text
#  max_active_users     :integer
#  monthly_price        :integer          default(0)
#  name                 :string
#  openapi_access       :boolean          default(FALSE)
#  price                :integer
#  sequence_number      :integer
#  support_level        :string
#  tag                  :string           default("regular")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class PricingPlan < ApplicationRecord
    validates :name, presence: true
    validates :price, :monthly_price, :annual_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :max_active_users, :human_agents, :ai_agents, :ai_responses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    
    serialize :integration_channels, Array # Menyimpan array channel (Livechat, WhatsApp, Telegram)
  end
  
