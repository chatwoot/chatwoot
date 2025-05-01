class RemovePortalMembers < ActiveRecord::Migration[7.0]
  def up
    drop_table :portal_members
  end

  def down
    create_table :portal_members do |t|
      t.references :portal, index: false
      t.references :user, index: false
      t.timestamps
    end

    add_index :portal_members, [:portal_id, :user_id], unique: true
    add_index :portal_members, [:user_id, :portal_id], unique: true
  end
end
