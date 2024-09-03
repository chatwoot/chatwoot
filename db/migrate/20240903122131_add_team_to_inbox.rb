class AddTeamToInbox < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :team_id, :integer, null: true
  end
end
