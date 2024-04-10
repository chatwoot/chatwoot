class AddArchiveColumnToPortal < ActiveRecord::Migration[6.1]
  def change
    add_column :portals, :archived, :boolean, default: false
  end
end
