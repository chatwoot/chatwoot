# frozen_string_literal: true

class CreateAssignmentPolicies < ActiveRecord::Migration[7.1]
  def change
    create_table :assignment_policies do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false, limit: 255
      t.text :description
      t.integer :assignment_order, null: false, default: 0 # 0: round_robin, 1: balanced
      t.integer :conversation_priority, null: false, default: 0 # 0: earliest_created, 1: longest_waiting
      t.integer :fair_distribution_limit, null: false, default: 100
      t.integer :fair_distribution_window, null: false, default: 3600 # seconds
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :assignment_policies, [:account_id, :name], unique: true
    add_index :assignment_policies, :enabled
  end
end
