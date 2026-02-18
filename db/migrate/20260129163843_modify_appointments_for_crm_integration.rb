# frozen_string_literal: true

class ModifyAppointmentsForCrmIntegration < ActiveRecord::Migration[7.1]
  def change
    # Rename existing columns for consistency
    rename_column :appointments, :start_time, :scheduled_at
    rename_column :appointments, :end_time, :ended_at

    # Add type and status enums
    add_column :appointments, :appointment_type, :integer, null: false, default: 0
    add_column :appointments, :status, :integer, null: false, default: 0

    # Add references (owner_id nullable initially, will be enforced in model)
    add_reference :appointments, :owner, foreign_key: { to_table: :users }, null: true,
                                         index: true, if_not_exists: true
    add_reference :appointments, :inbox, foreign_key: true, null: true,
                                         index: true, if_not_exists: true
    add_reference :appointments, :conversation, foreign_key: true, null: true,
                                                index: true, if_not_exists: true

    # Add timestamp fields
    add_column :appointments, :started_at, :datetime
    add_column :appointments, :duration_minutes, :integer

    # Add type-specific fields
    add_column :appointments, :meeting_url, :string
    add_column :appointments, :phone_number, :string

    # Add JSONB fields
    add_column :appointments, :participants, :jsonb, default: {}
    add_column :appointments, :external_ids, :jsonb, default: {}
    add_column :appointments, :additional_attributes, :jsonb, default: {}

    # Add soft delete
    add_column :appointments, :discarded_at, :datetime

    # Add composite indexes
    add_index :appointments, [:account_id, :scheduled_at], if_not_exists: true
    add_index :appointments, [:owner_id, :status], if_not_exists: true
    add_index :appointments, :discarded_at, if_not_exists: true
    add_index :appointments, :status, if_not_exists: true
  end
end
