# frozen_string_literal: true

class CreateEnterpriseInboxCapacityLimits < ActiveRecord::Migration[7.1]
  def change
    create_table :enterprise_inbox_capacity_limits do |t|
      t.references :agent_capacity_policy, null: false, index: { name: 'index_inbox_limits_on_capacity_policy' }
      t.references :inbox, null: false, index: true
      t.integer :conversation_limit, null: false

      t.timestamps
    end

    add_index :enterprise_inbox_capacity_limits, [:agent_capacity_policy_id, :inbox_id], unique: true, name: 'unique_policy_inbox_limit'
  end
end