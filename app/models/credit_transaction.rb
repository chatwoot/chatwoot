# == Schema Information
#
# Table name: credit_transactions
#
#  id               :bigint           not null, primary key
#  amount           :integer          not null
#  credit_type      :string           not null
#  description      :string
#  metadata         :jsonb
#  transaction_type :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#
# Indexes
#
#  index_credit_transactions_on_account_id                 (account_id)
#  index_credit_transactions_on_account_id_and_created_at  (account_id,created_at)
#
class CreditTransaction < ApplicationRecord
  belongs_to :account

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: %w[grant expire use topup] }
  validates :credit_type, presence: true, inclusion: { in: %w[monthly topup mixed] }

  scope :recent, -> { order(created_at: :desc) }
end
