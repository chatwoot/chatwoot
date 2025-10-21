class ChangeVapiAgentIdUniquenessToScopedByAccount < ActiveRecord::Migration[7.1]
  def change
    # Remove the old unique index on vapi_agent_id
    remove_index :vapi_agents, :vapi_agent_id

    # Add a new composite unique index on vapi_agent_id scoped to account_id
    add_index :vapi_agents, [:vapi_agent_id, :account_id], unique: true
  end
end
