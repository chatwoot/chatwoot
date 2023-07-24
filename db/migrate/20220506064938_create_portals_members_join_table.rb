class CreatePortalsMembersJoinTable < ActiveRecord::Migration[6.1]
  def change
    create_join_table :portals, :users, table_name: :portals_members do |t|
      t.index :portal_id
      t.index :user_id
      t.index [:portal_id, :user_id], unique: true
    end
  end
end
