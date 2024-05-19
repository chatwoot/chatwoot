class ChangeColumnsInContact < ActiveRecord::Migration[7.0]
  def change
    rename_column :contacts, :assignee_id_in_leads, :assignee_id
    remove_column :contacts, :assignee_id_in_deals, :integer
  end
end
