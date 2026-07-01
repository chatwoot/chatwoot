class AddAssignedAgentIdToContacts < ActiveRecord::Migration[7.0]
  def change
    add_reference :contacts, :assigned_agent, foreign_key: { to_table: :users }, null: true, index: true
  end
end
