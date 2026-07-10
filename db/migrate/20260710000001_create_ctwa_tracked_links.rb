class CreateCtwaTrackedLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :ctwa_tracked_links do |t|
      t.references :account, null: false, index: { name: 'idx_ctwa_tracked_links_account' },
                             foreign_key: { on_delete: :cascade }
      t.references :inbox, null: false, index: { name: 'idx_ctwa_tracked_links_inbox' },
                           foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :code, null: false, index: { unique: true, name: 'idx_ctwa_tracked_links_code' }
      t.string :prefilled_text, default: ''
      t.integer :clicks_count, default: 0, null: false
      t.integer :conversations_count, default: 0, null: false
      t.bigint :created_by_id

      t.timestamps
    end
  end
end
