class AddPoInfoToContact < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :po_agent_id, :integer, null: true
    add_column :contacts, :po_team_id, :integer, null: true
    add_column :contact_transactions, :agent_id, :integer, null: true
    add_column :contact_transactions, :team_id, :integer, null: true
  end
end
