class AddIndexOnAgentSessionsUsedFaqIds < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :agent_sessions, :used_faq_ids, using: :gin, algorithm: :concurrently
  end
end
