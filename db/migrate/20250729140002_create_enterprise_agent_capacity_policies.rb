# frozen_string_literal: true

class CreateEnterpriseAgentCapacityPolicies < ActiveRecord::Migration[7.1]
  def change
    create_table :enterprise_agent_capacity_policies do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false, limit: 255
      t.text :description
      t.jsonb :exclusion_rules, default: {}, null: false

      t.timestamps
    end

    add_index :enterprise_agent_capacity_policies, [:account_id, :name], unique: true, name: 'unique_capacity_policy_name_per_account'
    add_index :enterprise_agent_capacity_policies, :exclusion_rules, using: :gin, name: 'index_capacity_policies_on_exclusion_rules'
  end
end
