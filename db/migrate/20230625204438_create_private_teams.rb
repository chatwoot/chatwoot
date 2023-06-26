class CreatePrivateTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :private, :boolean, default: false, null: false
  end
end
