class AddFieldsToContact < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :team_id, :integer
    add_column :contacts, :assignee_id_in_leads, :integer
    add_column :contacts, :assignee_id_in_deals, :integer
    add_column :contacts, :initial_channel_id, :integer
    add_column :contacts, :initial_channel_type, :string
    add_column :contacts, :first_reply_created_at, :datetime
    add_column :contacts, :last_stage_changed_at, :datetime
  end
end
