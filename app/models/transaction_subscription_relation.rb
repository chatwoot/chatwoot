# == Schema Information
#
# Table name: transaction_subscription_relations
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  subscription_id :bigint           not null
#  transaction_id  :bigint           not null
#
# Indexes
#
#  index_transaction_subscription_relations_on_subscription_id  (subscription_id)
#  index_transaction_subscription_relations_on_transaction_id   (transaction_id)
#  index_tx_sub_rel                                             (transaction_id,subscription_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (subscription_id => subscriptions.id) ON DELETE => cascade
#  fk_rails_...  (transaction_id => transactions.id) ON DELETE => cascade
#
class TransactionSubscriptionRelation < ApplicationRecord
  belongs_to :transaction_rel, class_name: 'Transaction', foreign_key: 'transaction_id'
  belongs_to :subscription
end
