class AddUniqueIndexToAppliedSlas < ActiveRecord::Migration[7.0]
  def change
    add_index :applied_slas,
              [:account_id, :sla_policy_id, :conversation_id],
              unique: true,
              name: 'index_applied_slas_on_account_sla_policy_conversation'
  end
end
