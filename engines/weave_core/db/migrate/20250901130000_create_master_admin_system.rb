class CreateMasterAdminSystem < ActiveRecord::Migration[7.1]
  def change
    # Master Admin Users - WeaveCode staff who can manage all tenants
    create_table :weave_core_master_admins do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :role, null: false, default: 'admin' # admin, super_admin, support
      t.boolean :active, default: true
      t.text :permissions # JSON array of specific permissions
      t.string :encrypted_password
      t.string :session_token
      t.datetime :last_login_at
      t.string :last_login_ip
      t.timestamps
    end
    
    # Master Admin Sessions for authentication
    create_table :weave_core_master_admin_sessions do |t|
      t.references :master_admin, null: false, foreign_key: { to_table: :weave_core_master_admins }
      t.string :session_token, null: false, index: { unique: true }
      t.string :ip_address
      t.string :user_agent
      t.datetime :expires_at
      t.timestamps
    end
    
    # Audit Log for all master admin actions
    create_table :weave_core_admin_audit_logs do |t|
      t.references :master_admin, null: false, foreign_key: { to_table: :weave_core_master_admins }
      t.references :account, null: true, foreign_key: { to_table: :accounts } # Target account
      t.string :action_type, null: false # suspend, reactivate, force_upgrade, etc
      t.string :resource_type # account, subscription, feature_toggle
      t.string :resource_id
      t.text :action_details # JSON with action specifics
      t.text :reason # Why the action was taken
      t.string :ip_address
      t.timestamps
    end
    
    # System Alerts for failing integrations and limits
    create_table :weave_core_system_alerts do |t|
      t.references :account, null: true, foreign_key: { to_table: :accounts }
      t.string :alert_type, null: false # payment_failed, integration_down, limit_exceeded, etc
      t.string :severity, null: false, default: 'medium' # low, medium, high, critical
      t.string :title, null: false
      t.text :description
      t.text :metadata # JSON with alert details
      t.string :status, default: 'active' # active, acknowledged, resolved
      t.references :acknowledged_by, null: true, foreign_key: { to_table: :weave_core_master_admins }
      t.datetime :acknowledged_at
      t.references :resolved_by, null: true, foreign_key: { to_table: :weave_core_master_admins }
      t.datetime :resolved_at
      t.timestamps
    end
    
    # Tenant Benefits - special benefits granted by master admins
    create_table :weave_core_tenant_benefits do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.references :granted_by, null: false, foreign_key: { to_table: :weave_core_master_admins }
      t.string :benefit_type, null: false # extended_trial, free_upgrade, feature_unlock, etc
      t.string :benefit_value # JSON or string value
      t.text :description
      t.datetime :expires_at
      t.boolean :active, default: true
      t.text :grant_reason
      t.timestamps
    end
    
    add_index :weave_core_master_admin_sessions, [:expires_at]
    add_index :weave_core_admin_audit_logs, [:action_type, :created_at]
    add_index :weave_core_system_alerts, [:alert_type, :status]
    add_index :weave_core_system_alerts, [:severity, :status]
    add_index :weave_core_tenant_benefits, [:benefit_type, :active]
    add_index :weave_core_tenant_benefits, [:expires_at]
  end
end