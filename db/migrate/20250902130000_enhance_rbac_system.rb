class EnhanceRbacSystem < ActiveRecord::Migration[7.1]
  def up
    # Add owner role to AccountUser enum
    execute <<-SQL
      ALTER TYPE account_user_role ADD VALUE IF NOT EXISTS 'owner';
      ALTER TYPE account_user_role ADD VALUE IF NOT EXISTS 'finance';
      ALTER TYPE account_user_role ADD VALUE IF NOT EXISTS 'support';
    SQL

    # Add role hierarchy to account_users
    add_column :account_users, :role_hierarchy, :integer, default: 0
    add_column :account_users, :is_primary_owner, :boolean, default: false
    add_column :account_users, :permissions_override, :jsonb, default: {}

    # Update existing administrators to have proper hierarchy
    execute <<-SQL
      UPDATE account_users 
      SET role_hierarchy = 100 
      WHERE role = 1; -- administrators
      
      UPDATE account_users 
      SET role_hierarchy = 50 
      WHERE role = 0; -- agents
    SQL

    # Update CustomRole model (if it exists in current migration context)
    if table_exists?(:custom_roles)
      add_column :custom_roles, :is_system_role, :boolean, default: false
      add_column :custom_roles, :role_type, :string
      add_column :custom_roles, :role_hierarchy, :integer, default: 0
      add_column :custom_roles, :role_color, :string
      
      add_index :custom_roles, :role_type
      add_index :custom_roles, :is_system_role
      add_index :custom_roles, :role_hierarchy
    end

    # Add indexes for performance
    add_index :account_users, :role_hierarchy
    add_index :account_users, :is_primary_owner
    add_index :account_users, [:account_id, :is_primary_owner], unique: true, where: 'is_primary_owner = true'
  end

  def down
    # Remove columns
    if table_exists?(:custom_roles)
      remove_column :custom_roles, :is_system_role
      remove_column :custom_roles, :role_type
      remove_column :custom_roles, :role_hierarchy  
      remove_column :custom_roles, :role_color
    end

    remove_column :account_users, :role_hierarchy
    remove_column :account_users, :is_primary_owner
    remove_column :account_users, :permissions_override

    # Note: Cannot remove enum values in PostgreSQL without recreating the type
    # This is intentionally left as-is to avoid data loss
  end
end