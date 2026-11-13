class CreateChannelGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_groups do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false, limit: 100

      t.timestamps
    end
    add_index :channel_groups, 'account_id, lower(name)', unique: true, name: 'index_channel_groups_on_account_id_and_name'
    add_reference :inboxes, :channel_group, foreign_key: { on_delete: :nullify }
  end
end
