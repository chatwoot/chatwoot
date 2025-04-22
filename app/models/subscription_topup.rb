# == Schema Information
#
# Table name: subscription_topups
#
#  id                    :bigint           not null, primary key
#  amount                :integer          not null
#  expires_at            :datetime
#  paid_at               :datetime
#  payment_details       :text
#  payment_method        :string
#  payment_url           :string
#  price                 :decimal(10, 2)   not null
#  status                :string           not null
#  topup_type            :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  duitku_order_id       :string
#  duitku_transaction_id :string
#  subscription_id       :bigint           not null
#
# Indexes
#
#  index_subscription_topups_on_subscription_id  (subscription_id)
#
# Foreign Keys
#
#  fk_rails_...  (subscription_id => subscriptions.id)
#
class SubscriptionTopup < ApplicationRecord
  belongs_to :subscription
  has_many :transaction_topup_relations, dependent: :destroy
  has_many :transactions, through: :transaction_topup_relations
  
  validates :topup_type, inclusion: { in: ['max_active_users', 'ai_responses'] }
  validates :amount, :price, numericality: { greater_than: 0 }
  
  scope :active, -> { where(status: 'paid').where('expires_at > ?', Time.current) }
  
  def active?
    status == 'paid' && expires_at > Time.current
  end
end
