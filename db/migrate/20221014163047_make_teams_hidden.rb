class MakeTeamsHidden < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :hidden, :boolean, default: false, null: false
  end
end
