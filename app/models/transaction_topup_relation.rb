# == Schema Information
#
# Table name: transaction_topup_relations
#
#  id             :bigint           not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  topup_id       :bigint           not null
#  transaction_id :bigint           not null
#
# Indexes
#
#  index_transaction_topup_relations_on_topup_id        (topup_id)
#  index_transaction_topup_relations_on_transaction_id  (transaction_id)
#  index_tx_topup_rel                                   (transaction_id,topup_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (topup_id => subscription_topups.id) ON DELETE => cascade
#  fk_rails_...  (transaction_id => transactions.id) ON DELETE => cascade
#
class TransactionTopupRelation < ApplicationRecord
  belongs_to :transaction
  belongs_to :topup, class_name: 'SubscriptionTopup'
end
