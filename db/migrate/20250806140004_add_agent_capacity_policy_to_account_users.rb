# frozen_string_literal: true

class AddAgentCapacityPolicyToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :account_users, :agent_capacity_policy, null: true, index: true
  end
end
