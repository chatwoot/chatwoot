# == Schema Information
#
# Table name: transactions
#
#  id               :bigint           not null, primary key
#  action           :string           default("pay")
#  duration         :integer
#  duration_unit    :string
#  expiry_date      :datetime
#  metadata         :jsonb
#  notes            :text
#  package_name     :string
#  package_type     :string           not null
#  payment_date     :datetime
#  payment_method   :string
#  payment_url      :string
#  price            :decimal(10, 2)   not null
#  status           :string           not null
#  transaction_date :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  transaction_id   :string           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_transactions_on_account_id        (account_id)
#  index_transactions_on_package_type      (package_type)
#  index_transactions_on_status            (status)
#  index_transactions_on_transaction_date  (transaction_date)
#  index_transactions_on_transaction_id    (transaction_id) UNIQUE
#  index_transactions_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :account

  has_many :transaction_topup_relations, dependent: :destroy
  has_many :topups, through: :transaction_topup_relations, source: :topup

  has_many :transaction_subscription_relations, dependent: :destroy
  has_many :subscriptions, through: :transaction_subscription_relations

  validates :transaction_id, presence: true, uniqueness: true
  validates :package_type, :price, :status, presence: true

  # Custom property
  def status_payment
    return 'paid' if status == 'paid'
    return 'failed' if expiry_date.present? && expiry_date < Time.current
    'pending'
  end

  def as_json(options = {})
    super(options).merge(status_payment: status_payment)
  end
end
