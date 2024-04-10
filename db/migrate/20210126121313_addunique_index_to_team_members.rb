class AdduniqueIndexToTeamMembers < ActiveRecord::Migration[6.0]
  def change
    add_index :teams, [:name, :account_id], unique: true
    add_index :team_members, [:team_id, :user_id], unique: true
  end
end
