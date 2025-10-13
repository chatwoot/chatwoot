# == Schema Information
#
# Table name: subscription_payments
#
#  id                    :bigint           not null, primary key
#  amount                :decimal(10, 2)   not null
#  expires_at            :datetime
#  paid_at               :datetime
#  payment_details       :text
#  payment_method        :string
#  payment_url           :string
#  status                :string           default("pending"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  duitku_order_id       :string           not null
#  duitku_transaction_id :string
#  subscription_id       :bigint           not null
#
# Indexes
#
#  index_subscription_payments_on_duitku_order_id  (duitku_order_id)
#  index_subscription_payments_on_subscription_id  (subscription_id)
#
# Foreign Keys
#
#  fk_rails_...  (subscription_id => subscriptions.id)
#
class SubscriptionPayment < ApplicationRecord
    belongs_to :subscription
    
    validates :amount, numericality: { greater_than_or_equal_to: 0 }  # Allow 0 for voucher discounts
    validates :duitku_order_id, presence: true
    validates :status, inclusion: { in: %w(pending paid failed cancelled expired) }
    
    # Method untuk mengupdate status pembayaran
    def mark_as_paid
      update(status: 'paid', paid_at: Time.now)
      subscription.update(payment_status: 'paid')
      subscription.extend_period
      subscription.update_status
    end
    
    # Method untuk mengupdate status pembayaran menjadi failed
    def mark_as_failed
      update(status: 'failed')
      subscription.update(payment_status: 'failed')
    end
end
