# == Schema Information
#
# Table name: subscription_plans
#
#  id                 :bigint           not null, primary key
#  annual_price       :decimal(16, 2)   not null
#  available_channels :text             default([]), is an Array
#  description        :text
#  duration_days      :integer
#  features           :jsonb            not null
#  is_active          :boolean          default(TRUE)
#  max_ai_agents      :integer          default(0), not null
#  max_ai_responses   :integer          default(0), not null
#  max_human_agents   :integer          default(0), not null
#  max_mau            :integer          default(0), not null
#  monthly_price      :decimal(16, 2)   not null
#  name               :string           not null
#  support_level      :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class SubscriptionPlan < ApplicationRecord
  has_many :subscriptions
  has_and_belongs_to_many :vouchers

  validates :description, presence: true
  validates :name, presence: true
  validates :max_mau, :max_ai_agents, :max_ai_responses, :max_human_agents, :max_channels, numericality: { greater_than_or_equal_to: 0 }
  validates :monthly_price, :annual_price, numericality: { greater_than_or_equal_to: 0 }

  # Method untuk mencari plan berdasarkan nama
  def self.find_by_name(name)
    where('lower(name) = ?', name.downcase).first
  end

  # Method untuk mendapatkan daftar channel yang tersedia
  def channel_list
    available_channels.join(', ')
  end

  # Method untuk mengecek fitur tersedia atau tidak
  def has_feature?(feature_name)
    case feature_name
    when 'website'
      available_channels.include?('website')
    when 'whatsapp'
      available_channels.include?('whatsapp')
    when 'telegram'
      available_channels.include?('telegram')
    when 'api'
      available_channels.include?('api')
    when 'unlimited_mau'
      max_mau == 0 # 0 means unlimited
    else
      false
    end
  end
end
