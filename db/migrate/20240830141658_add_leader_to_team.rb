class AddLeaderToTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :team_members, :leader, :boolean, null: false, default: false
  end
end
