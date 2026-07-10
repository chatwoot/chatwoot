class CreateCtwaTrackedLinkClicks < ActiveRecord::Migration[7.1]
  def change
    create_table :ctwa_tracked_link_clicks do |t|
      t.references :account, null: false, index: { name: 'idx_ctwa_tracked_link_clicks_account' },
                             foreign_key: { on_delete: :cascade }
      t.references :tracked_link, null: false, index: { name: 'idx_ctwa_tracked_link_clicks_link' },
                                  foreign_key: { to_table: :ctwa_tracked_links, on_delete: :cascade }
      t.string :token, null: false, index: { unique: true, name: 'idx_ctwa_tracked_link_clicks_token' }
      t.jsonb :params, default: {}, null: false
      t.string :user_agent, limit: 255
      t.references :conversation, index: { name: 'idx_ctwa_tracked_link_clicks_conversation' },
                                  foreign_key: { on_delete: :nullify }
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :ctwa_tracked_link_clicks, [:tracked_link_id, :created_at], name: 'idx_ctwa_tracked_link_clicks_link_created'
  end
end
