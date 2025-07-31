# frozen_string_literal: true

class CreateLeaves < ActiveRecord::Migration[7.1]
  def change
    create_table :leaves do |t|
      t.references :account, null: false
      t.references :account_user, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :leave_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :reason
      t.references :approved_by
      t.datetime :approved_at

      t.timestamps
    end

    add_index :leaves, :start_date
    add_index :leaves, :end_date
    add_index :leaves, :status
    add_index :leaves, [:account_user_id, :start_date, :end_date], name: 'index_leaves_on_account_user_and_dates'
    add_index :leaves, [:account_id, :status], name: 'index_leaves_on_account_and_status'
  end
end
