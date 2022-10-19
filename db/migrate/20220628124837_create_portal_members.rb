class CreatePortalMembers < ActiveRecord::Migration[6.1]
  def change
    create_table :portal_members do |t|
      t.bigint :portal_id
      t.bigint :user_id
      t.timestamps
    end

    add_index :portal_members, [:portal_id, :user_id], unique: true
    add_index :portal_members, [:user_id, :portal_id], unique: true
  end
end
