# frozen_string_literal: true

class InstallAudited < ActiveRecord::Migration[6.1]
  # rubocop:disable RMetrics/MethodLength
  def self.up
    create_table :audits, :force => true do |t|
      t.bigint :auditable_id
      t.string :auditable_type
      t.bigint :associated_id
      t.string :associated_type
      t.bigint :user_id
      t.string :user_type
      t.string :username
      t.string :action
      t.jsonb :audited_changes
      t.integer :version, :default => 0
      t.string :comment
      t.string :remote_address
      t.string :request_uuid
      t.datetime :created_at
    end
    # rubocop:enable RMetrics/MethodLength

    add_index :audits, [:auditable_type, :auditable_id, :version], :name => 'auditable_index'
    add_index :audits, [:associated_type, :associated_id], :name => 'associated_index'
    add_index :audits, [:user_id, :user_type], :name => 'user_index'
    add_index :audits, :request_uuid
    add_index :audits, :created_at
  end

  def self.down
    drop_table :audits
  end
end
