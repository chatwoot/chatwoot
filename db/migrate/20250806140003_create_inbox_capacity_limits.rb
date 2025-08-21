# frozen_string_literal: true

class CreateInboxCapacityLimits < ActiveRecord::Migration[7.1]
  def change
    create_table :inbox_capacity_limits do |t|
      t.references :agent_capacity_policy, null: false, index: true
      t.references :inbox, null: false, index: true
      t.integer :conversation_limit, null: false

      t.timestamps
    end

    add_index :inbox_capacity_limits, [:agent_capacity_policy_id, :inbox_id], unique: true
  end
end
