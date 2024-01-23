# == Schema Information
#
# Table name: applied_slas
#
#  id              :bigint           not null, primary key
#  sla_status      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  sla_policy_id   :bigint           not null
#
# Indexes
#
#  index_applied_slas_on_account_id       (account_id)
#  index_applied_slas_on_conversation_id  (conversation_id)
#  index_applied_slas_on_sla_policy_id    (sla_policy_id)
#
class AppliedSla < ApplicationRecord
  belongs_to :account
  belongs_to :sla_policy
  belongs_to :conversation
end
