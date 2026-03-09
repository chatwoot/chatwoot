# frozen_string_literal: true

class CreateAgentCapacityPolicies < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_capacity_policies do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false, limit: 255
      t.text :description
      t.jsonb :exclusion_rules, default: {}, null: false

      t.timestamps
    end
  end
end
