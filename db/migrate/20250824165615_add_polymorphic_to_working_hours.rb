# frozen_string_literal: true

class AddPolymorphicToWorkingHours < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_column :working_hours, :workable_type, :string
    add_column :working_hours, :workable_id, :bigint

    add_index :working_hours, [:workable_type, :workable_id], algorithm: :concurrently
  end

  def down
    remove_index :working_hours, column: [:workable_type, :workable_id], if_exists: true
    remove_column :working_hours, :workable_id
    remove_column :working_hours, :workable_type
  end
end
