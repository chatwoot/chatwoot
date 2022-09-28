class ChangeKbasePortalsToPortals < ActiveRecord::Migration[6.1]
  def change
    rename_table :kbase_portals, :portals
  end
end
