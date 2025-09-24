# == Schema Information
#
# Table name: subscriptions
#
#  id                      :bigint           not null, primary key
#  additional_ai_responses :integer          default(0), not null
#  additional_mau          :integer          default(0), not null
#  amount_paid             :decimal(10, 2)
#  available_channels      :text             default([]), is an Array
#  billing_cycle           :string           default("monthly"), not null
#  ends_at                 :datetime         not null
#  last_notify_expiry      :datetime
#  max_ai_agents           :integer          default(0), not null
#  max_ai_responses        :integer          default(0), not null
#  max_channels            :integer          default(0)
#  max_human_agents        :integer          default(0), not null
#  max_mau                 :integer          default(0), not null
#  payment_status          :string           default("pending"), not null
#  plan_name               :string           not null
#  price                   :decimal(10, 2)   not null
#  starts_at               :datetime         not null
#  status                  :string           default("pending"), not null
#  support_level           :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#  duitku_order_id         :string
#  subscription_plan_id    :bigint
#
# Indexes
#
#  index_subscriptions_on_account_id            (account_id)
#  index_subscriptions_on_subscription_plan_id  (subscription_plan_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Subscription < ApplicationRecord
  has_many :transaction_subscription_relations, dependent: :destroy
  has_many :transactions, through: :transaction_subscription_relations
  belongs_to :account
  belongs_to :subscription_plan, optional: true
  has_many :subscription_payments
  has_one :subscription_usage
  has_many :subscription_topups
  # has_many :account, foreign_key: 'active_subscription_id'

  validates :plan_name, :starts_at, :ends_at, presence: true
  validates :status, inclusion: { in: %w[pending active expired cancelled inactive failed] }
  validates :payment_status, inclusion: { in: %w[pending paid failed cancelled expired] }
  validates :billing_cycle, inclusion: { in: %w[monthly quarterly halfyear yearly] }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  after_create :create_usage_record

  scope :active, -> { where(status: 'active').where('ends_at > ?', Time.now) }

  # Method untuk membuat record usage
  def create_usage_record
    create_subscription_usage if subscription_usage.nil?
  end

  # Method untuk mengecek subscription aktif atau tidak
  def active?
    status == 'active' && (ends_at.nil? || ends_at > Time.current)
  end

  # Method untuk mengupdate status subscription
  def update_status
    if Time.now > ends_at
      update(status: 'expired')
      # Update user subscription status
      # users.update_all(subscription_status: 'expired')
    elsif payment_status == 'paid' && status == 'pending'
      update(status: 'active')
      # Update user subscription status
      # users.update_all(subscription_status: 'active')
    end
  end

  # Method untuk memperpanjang subscription
  def extend_period
    current_ends_at = ends_at > Time.now ? ends_at : Time.now

    new_ends_at = if billing_cycle == 'monthly'
                    current_ends_at + 30.days
                  else
                    current_ends_at + 365.days
                  end

    update(ends_at: new_ends_at)
  end

  # Method untuk mengecek penggunaan
  def check_limits
    usage = subscription_usage || create_usage_record
    {
      mau: {
        limit: max_mau,
        used: usage.mau_count,
        available: max_mau == 0 ? 'Unlimited' : (max_mau - usage.mau_count)
      },
      ai_responses: {
        limit: max_ai_responses,
        used: usage.ai_responses_count,
        available: max_ai_responses == 0 ? 'Unlimited' : (max_ai_responses - usage.ai_responses_count)
      }
    }
  end

  # Method untuk mendapatkan channel yang tersedia
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
