class CreateSuperAdminAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :super_admin_audit_logs do |t|
      t.bigint :super_admin_id, null: false
      t.bigint :target_user_id
      t.string :action, null: false
      t.jsonb :metadata, null: false, default: {}
      t.string :ip_address
      t.text :user_agent
      t.datetime :created_at, null: false

      t.index :super_admin_id
      t.index :target_user_id
      t.index :created_at
    end
  end
end
