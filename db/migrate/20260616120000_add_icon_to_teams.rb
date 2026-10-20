class AddIconToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :icon, :string, default: '' unless column_exists?(:teams, :icon)
    add_column :teams, :icon_color, :string, default: '' unless column_exists?(:teams, :icon_color)
  end
end
