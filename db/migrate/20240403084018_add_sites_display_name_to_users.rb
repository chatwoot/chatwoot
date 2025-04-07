class AddSitesDisplayNameToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :azar_display_name, :string
    add_column :users, :mono_display_name, :string
    add_column :users, :gbits_display_name, :string
  end
end
