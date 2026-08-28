class CreateCopilotPendingAdminActions < ActiveRecord::Migration[7.2]
  def change
    create_table :copilot_pending_admin_actions do |t|
      t.references :account, null: false, index: true
      t.references :user, null: false, index: true
      t.references :copilot_thread, null: false, index: true
      t.string :tool_name, null: false
      t.jsonb :action_params, null: false, default: {}
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :copilot_pending_admin_actions, %i[copilot_thread_id status]
  end
end
