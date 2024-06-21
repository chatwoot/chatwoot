class AddNotNullUniqueColorToTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :color, :string, null: false, default: '#D7DBDF'
  end
end
